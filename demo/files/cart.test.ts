import { describe, expect, it } from "vitest";
import { Cart } from "./cart";

describe("cart", () => {
  it("starts empty", () => {
    expect(new Cart().items).toEqual([]);
  });

  it("adds an item", () => {
    const cart = new Cart();
    cart.add({ name: "apple", price: 1 });
    expect(cart.items).toHaveLength(1);
  });
});
