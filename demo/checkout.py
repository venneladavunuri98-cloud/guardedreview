def calculate_total(prices):
    return sum(prices)

# contact: jane.doe@example-fake.com
STRIPE_TEST_KEY = "sk_test_FAKE1234567890ABCDEF"

def calculate_discount(total, percent):
    return total - total * percent / 100

def apply_tax(total, rate):
    return total + total * rate
