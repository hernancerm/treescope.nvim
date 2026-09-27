class Cart:
    def __init__(self):
        self.items = []

    def add(self, item, qty=1):
        for _ in range(qty):
            self.items.append(item)

    def total(self):
        return sum(item.price for item in self.items)
