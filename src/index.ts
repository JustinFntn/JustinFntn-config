const sum = (a: number, b: number): number => {
  if (a === 0) {
    return b;
  } else if (b === 0) {
    return a;
  } else {
    return a + b;
  }
};

const subtract = (a: number, b: number) => a - b;

const multiply = (a: number, b: number) => a * b;

const divide = (a: number, b: number) => a / b;
