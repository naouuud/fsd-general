# Write a Python function called factorial that takes a positive integer as a parameter and calculates its factorial.
# The factorial of a number is the product of all positive integers less than or equal to that number. For example,
# the factorial of 5 is 5*4*3*2*1 = 120.

def factorial(n: int) -> int:
    if n <= 1:
        return 1
    return n * factorial(n - 1)


print("0! = " + str(factorial(0)))
print("1! = " + str(factorial(1)))
print("2! = " + str(factorial(2)))
print("3! = " + str(factorial(3)))
print("4! = " + str(factorial(4)))
print("5! = " + str(factorial(5)))
print("6! = " + str(factorial(6)))
print("10! = " + str(factorial(10)))

# Write a Python function fizz_buzz that takes an integer n and for each integer from 1 to n it prints "Fizz" if the
# number is divisible by 3, "Buzz" if the number is divisible by 5, and "FizzBuzz" if the number is divisible by both
# 3 and 5. If the number is not divisible by 3 or 5, it should just print the number.


def fizz_buzz(n: int) -> str:
    res = ""
    for i in range(1, n + 1):
        if i % 3 == 0:
            res += "Fizz"
        elif i % 5 != 0:
            res += str(i)
        if i % 5 == 0:
            res += "Buzz"
        res += " "
    return res


print("FizzBuzz from 1 to 33: " + fizz_buzz(33))

# Create a Python function char_frequency that takes a string as input and returns a dictionary where the keys are
# characters and the values are the frequency of each character in the string.


def char_frequency(s: str) -> dict:
    res = {}
    for i in range(len(s)):
        if s[i] in res.keys():
            res[s[i]] += 1
        else:
            res[s[i]] = 1

    keys = list(res.keys())
    keys.sort()
    sorted_res = {}
    for key in keys:
        sorted_res[key] = res[key]

    return sorted_res


print("Alphabet: " + str(char_frequency("ABCDEFGHIJKLMNOPQRSTUVWXYZ")))
print("Hello World: " + str(char_frequency("Hello World")))
print("Full Stack Data Analysis: " + str(char_frequency("Full Stack Data Analysis")))

