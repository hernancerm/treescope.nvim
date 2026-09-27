package com.example.shop;

import java.util.List;

public class App {
    public static void main(String[] args) {
        Cart cart = new Cart();
        cart.add(new Item("apple", 1));
        System.out.println(cart.total());
    }
}
