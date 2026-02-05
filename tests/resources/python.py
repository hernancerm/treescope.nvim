# cursor-3f7a2b1c


def greet(name):
    # cursor-5k9m1p4x
    return f"Hello, {name}!"


# cursor-2q8r6t9v[jw]
def sayHello(name):
    return f"Hello, {name}!"


async def asyncFetch(url):
    # cursor-8l1o3c5a
    return "data"


def processData(data):
    def inner():
        # cursor-1u2v3w4x
        return data

    return inner()


def outer():
    def middle():
        def deepest():
            # cursor-5y6z7a8b
            return "deep"

        return deepest()

    return middle()


class MyClass:
    def method(self):
        # cursor-9i0j1k2l
        return "instance method"

    # cursor-a7cp3312[jw]
    def anotherMethod(self):
        return "another method"

    async def asyncMethod(self):
        # cursor-1n3b5j7c
        return "async instance method"

    @classmethod
    def classMethod(cls):
        # cursor-4e6g9s2u
        return "class method"

    @staticmethod
    def staticMethod():
        # cursor-7w2d4f8h
        return "static method"

    def methodWithNested(self):
        def nested():
            # cursor-6i4p8v2w
            return "nested in method"

        return nested()
