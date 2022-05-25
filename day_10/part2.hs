import Data.List
import Data.Maybe

openingChars :: [Char]
openingChars = ['(', '[', '{', '<']

openingToClosing :: Char -> Char
openingToClosing '(' = ')'
openingToClosing '[' = ']'
openingToClosing '{' = '}'
openingToClosing '<' = '>'
openingToClosing _ = error "Invalid opening character"

-- scores incomplete strings
synCheckIncompleteScore :: String -> Maybe Integer
synCheckIncompleteScore s =
  let
    calcScore :: Integer -> String -> Integer
    calcScore acc [] = acc
    calcScore acc (c:cs) =
      calcScore (5*acc + v) cs
      where
        v = case c of
          ')' -> 1
          ']' -> 2
          '}' -> 3
          '>' -> 4
          _ -> error "Invalid closing character"
  in
  -- calculate score if 'Just' result
  calcScore 0 <$> synCheckIncomplete s []

-- Finds the incomplete part of the string, if any.
synCheckIncomplete :: String -> [Char] -> Maybe [Char]
-- Base case: we are done
synCheckIncomplete "" xs = Just xs
-- No characters on the stack yet, so we add one
synCheckIncomplete (x:xs) []
  | x `elem` openingChars = synCheckIncomplete xs [openingToClosing x]
  -- already hit an illegal character
  | otherwise = Nothing
-- Check that whatever is on the stack is correct
synCheckIncomplete (x:xs) (y:ys)
  -- opening char
  | x `elem` openingChars = synCheckIncomplete xs (openingToClosing x:y:ys)
  -- closing char
  | x == y = (synCheckIncomplete xs ys)
  -- illegal char
  | otherwise = Nothing

main :: IO ()
main = do
  -- read input file as a newline separated list of strings
  input <- readFile "input.txt"
  -- split input into list of strings
  let inputList = lines input
  -- map over list of strings, removing Nothings
  let scores = mapMaybe synCheckIncompleteScore inputList
  -- get the median by sorting and taking the middle element
  let median = (sort scores) !! (length scores `div` 2)
  -- print the median
  print median
