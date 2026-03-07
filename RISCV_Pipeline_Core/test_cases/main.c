// int main() {
//     volatile int a = 5;
//     volatile int b = 10;
//     volatile int c = a + b;
//     return c;
// }
int sum_array(int n) {
    int result = 0;
    int i;
    for(i = 1; i <= n; i++) {
        result = result + i;
    }
    return result;
}

int main() {
    return sum_array(10);  // should return 55
}