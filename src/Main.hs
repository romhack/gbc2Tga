module Main where
import           Codec.Picture
import           Data.Binary.Get
import           Data.Bits
import qualified Data.ByteString.Lazy as Bs
import           Data.List
import           Data.List.Split
import           Data.Word
import           System.Environment

type Pal = [PixelRGB8]
type TileScanline = [Int] --8 pixels, each is color index: 0-3
type Tile = [TileScanline] -- 8 scanlines form Tile
imgWidth, imgHeight :: Int
imgWidth =  128
imgHeight = 128


main :: IO ()
main = getArgs >>= parse
  where
    parse ["-v"] = putStrLn "gbc2Tga tool 0.1"
    parse [str] = go str
    parse _ = putStrLn "Provide one name for pal and gfx"
    go name = do
      palRaw <- Bs.readFile $ name ++".pal"
      gfxRaw <- Bs.readFile $ name ++".gfx"
      let
        palettes = runGet getPalettes palRaw
        tiles = runGet getTiles gfxRaw

        pixMap = concat $ concat $ concatMap transpose $ chunksOf 16 tiles --convert tiles list to 2D map of indexes (width 16 tiles)
        pic = snd $ generateFoldImage foldFunc (pixMap, palettes) imgWidth imgHeight
      writeTga (name ++ ".tga") pic


foldFunc :: ([Int],[Pal]) -> Int -> Int -> (([Int],[Pal]), PixelRGB8)
foldFunc (pixMaps, pals) x y = ((tail pixMaps, pals), pal !! head pixMaps)
  where
    pal = pals !! palBlockNum
    palBlockNum = if x >= (imgWidth `div` 2)
                    then x `div` 16 + (y' `div` 2)*8 --right half of screen as normal
                    else x `div` 16 + ((y'+1) `div` 2)*8 --left half is 1 scanline forward
                    where y' = min (imgHeight - 4) y --game stops pal update after 124th scanline


getPalBlockNum :: Int -> Int -> Int --screen is divided by 16x2 blocks, get block number by coords
getPalBlockNum x y = if x >= (imgWidth `div` 2) then x `div` 16 + (y' `div` 2)*8 --right half of screen as normal
                                  else x `div` 16 + ((y'+1) `div` 2)*8 --left half is 1 scanline forward
                        where y' = min (imgHeight - 4) y --game stops pal update after 124th scanline

getTiles :: Get [Tile] --get color indexes, gfx stored as 2bpp planar format
getTiles = do
  empty <- isEmpty
  if empty
    then return []
    else do
      rawTile <- Bs.unpack <$> getLazyByteString 16 --1 tile = 16 bytes
      let
        dividedRawTile = chunksOf 2 rawTile --2 byte per scanline
        tile = map (\[l, h] -> getColorIndexes l h) dividedRawTile
      rest <- getTiles
      return (tile : rest)


getColorIndexes :: Word8 -> Word8 -> [Int]
getColorIndexes loBits hiBits = zipWith (+) loIdxs hiIdxs
  where --lo and hi bits stored in different bytes of gfx (planar)
    loIdxs = testBits' loBits
    hiIdxs = map (*2) $ testBits' hiBits
    testBits' x = map (go x) [7,6..0]
      where go a i =  if (a .&. bit i) == 0 then 0 else 1

getPalettes :: Get [Pal] --get 4-color palettes from raw bytestream
getPalettes = do
  empty <- isEmpty
  if empty
    then return []
    else do col0 <- getWord16le
            col1 <- getWord16le
            col2 <- getWord16le
            col3 <- getWord16le
            let pal = map deserializeColor [col0, col1, col2, col3]
            rest <- getPalettes
            return (pal:rest)

deserializeColor :: Word16 -> PixelRGB8
deserializeColor x = PixelRGB8 r g b --15 bpp bgr format of gbc palettes
  where --shiftL to compensate brightness
    r = fromIntegral $ (x .&. 0x1F) `shiftL` 3
    g = fromIntegral $ ((x `shiftR` 5) .&. 0x1F) `shiftL` 3
    b = fromIntegral $ ((x `shiftR` 10) .&. 0x1F) `shiftL` 3
