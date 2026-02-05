// cursor-3f7a2b1c

public class MyClass {
  public MyClass() {
    // cursor-8l1o3c5a
    System.out.println("Constructor");
  }

  // cursor-4e6g9s2u[jw]
  public MyClass(String param) {
    System.out.println("Constructor with param");
  }

  public void greet(String name) {
    // cursor-5k9m1p4x
    System.out.println("Hello, " + name);
  }

  // cursor-2q8r6t9v[jw]
  public void sayHello(String name) {
    System.out.println("Hello, " + name);
  }

  public static void staticMethod() {
    // cursor-7w2d4f8h
    System.out.println("Static method");
  }

  public <T> T genericMethod(T param) {
    // cursor-1n3b5j7c
    return param;
  }

  public void withAnonymousInner() {
    Runnable r = new Runnable() {
      public void run() {
        // cursor-6i4p8v2w
        System.out.println("Anonymous inner");
      }
    };
  }

  public void withInnerClass() {
    // cursor-9z8y7x6w
    InnerClass inner = new InnerClass();
    inner.innerMethod();
  }

  class InnerClass {
    public void innerMethod() {
      // cursor-5a4b3c2d[jw]
      System.out.println("Inner method");
    }
  }
}
