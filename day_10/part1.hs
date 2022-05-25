openingChars :: [Char]
openingChars = ['(', '[', '{', '<']

openingToClosing :: Char -> Char
openingToClosing '(' = ')'
openingToClosing '[' = ']'
openingToClosing '{' = '}'
openingToClosing '<' = '>'
openingToClosing _ = error "Invalid opening character"

synCheckIllegalValue :: String -> Integer
synCheckIllegalValue s = case synCheckFirstIllegalRec s [] of
  Just ')' -> 3
  Just ']' -> 57
  Just '}' -> 1197
  Just '>' -> 25137
  _ -> 0

-- Finds the first illegal character in a string.
synCheckFirstIllegalRec :: String -> [Char] -> Maybe Char
-- Base case: we are done
synCheckFirstIllegalRec "" _ = Nothing
-- No characters on the stack yet, so we add one
synCheckFirstIllegalRec (x:xs) []
  | x `elem` openingChars = synCheckFirstIllegalRec xs [openingToClosing x]
  -- already hit an illegal character
  | otherwise = Just x
-- Check that whatever is on the stack is correct
synCheckFirstIllegalRec (x:xs) (y:ys)
  -- opening char
  | x `elem` openingChars = synCheckFirstIllegalRec xs (openingToClosing x:y:ys)
  -- closing char
  | x == y = (synCheckFirstIllegalRec xs ys)
  -- illegal char
  | otherwise = Just x

main :: IO ()
main = do
  -- read input file as a newline separated list of strings
  input <- readFile "input.txt"
  -- split input into list of strings
  let inputList = lines input
  -- map synCheckIllegalValue to each string in inputList
  let result = map synCheckIllegalValue inputList
  print $ sum result
