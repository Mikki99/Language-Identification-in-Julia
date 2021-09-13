# JULIA FINAL PROJECT
# Language Identification
# Milan Miletic, SS 2020
# University of Tuebingen

using StatsBase
using IterTools

using DelimitedFiles
file = "training_edited.tsv" # Assumes that the file is in the same folder
data = readdlm(file, '\t', String; header=false)
;

# Creates a dictionary with languages as keys
# and arrays of words as values
langDict = Dict()
for i in 1:190
    langDict[data[i,:][1]] = split(data[i,:][2], " ")
end

# Function for getting character bigrams from a string
# (dots mark the beginning and the end of each word)
bigrams(s) = collect(partition("."*s*".", 2, 1))

# Creates a dictionary with languages as keys
# and bigram counts as values (the bigram counts
# are stored in the form of a new dictionary
# where bigrams are keys and counts are values)
bigramDict = Dict()
for (key, value) in langDict
    bigramArray = []
    for word in value
        for bigram in bigrams(word)
            push!(bigramArray, bigram)
        end
    end
    bigramDict[key] = countmap(bigramArray)
end

# Function to get a total number of bigram
# tokens in a language from a dictionary
function bigramCounter(dict, lang)
    count = 0
    for bigramCount in values(dict[lang])
        count += bigramCount
    end

    return count
end

# Function to get a number of UNIQUE bigram
# tokens in a language from a dictionary
uniqueBigramCounter(dict, lang) = length(dict[lang])

# Function that determines the language of the given word
# among given languages, based on a Naive Bayesian Classifier
# using character bigrams
function detectLang(word, dict)
    inputWordBigrams = bigrams(word)
    frequencyDict = Dict()
    for (lang, bigramCounts) in dict
        probabilityOfThisLang = 1
        for inputWordBigram in inputWordBigrams
            if inputWordBigram in keys(bigramCounts)
                probabilityOfThisBigram = (bigramCounts[inputWordBigram] + 1) / (bigramCounter(bigramDict, lang) + uniqueBigramCounter(bigramDict, lang))
            else
                probabilityOfThisBigram = 1 / (bigramCounter(bigramDict, lang) + uniqueBigramCounter(bigramDict, lang))
            end
            probabilityOfThisLang *= probabilityOfThisBigram
        end
        frequencyDict[lang] = probabilityOfThisLang
    end
    return findmax(frequencyDict)[2]
end

# MAIN
println("\nLanguage Identification\n")
print("Enter a word: ")

# Input word is also normalized to lowercase
inputWord = lowercase(readline())

# The program won't accept strings that include digits
# or any punctuation other than a hyphen, so the user
# would be prompted to reenter the word in case of an
# invalid one
while occursin(r"\d|[.,!?;:\\'\"]", inputWord)
    println("\nError!")
    print("Please enter a valid word: ")
    global inputWord = lowercase(readline())
end

println()


exactMatches = [] # Array of languages where the inputWord appears
for (lang, words) in langDict
    if inputWord in words
        push!(exactMatches, lang)
    end
end

if length(exactMatches) == 1
    println("Detected Language: " * exactMatches[1])
elseif length(exactMatches) == 0
    println("Detected Language: " * detectLang(inputWord, bigramDict))
elseif length(exactMatches) > 1
    shortlistDict = Dict()
    for lang in exactMatches
        shortlistDict[lang] = bigramDict[lang]
    end
    println("Detected Language: " * detectLang(inputWord, shortlistDict))
end
