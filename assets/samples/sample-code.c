/*
 * sample-code.c
 * サンプルCソースファイル
 * 
 * このファイルはコーディング規約チェッカーのテスト用です
 */

#include <stdio.h>
#include <stdlib.h>

#define MAX_SIZE 100
#define PI 3.14159

// グローバル変数
int globalCounter = 0;

/*
 * 関数: calculateSum
 * 説明: 二つの整数の和を計算する
 * 引数: a - 第一の整数, b - 第二の整数
 * 戻り値: 二つの整数の和
 */
int calculateSum(int a, int b) {
    return a + b;
}

/*
 * 関数: printArray
 * 説明: 配列の内容を表示する
 * 引数: arr - 整数配列, size - 配列のサイズ
 */
void printArray(int arr[], int size) {
    int i;
    printf("配列の内容: ");
    for (i = 0; i < size; i++) {
        printf("%d ", arr[i]);
    }
    printf("\n");
}

/*
 * メイン関数
 */
int main() {
    int numbers[5] = {1, 2, 3, 4, 5};
    int sum;
    
    // 配列の表示
    printArray(numbers, 5);
    
    // 合計計算
    sum = calculateSum(10, 20);
    printf("10 + 20 = %d\n", sum);
    
    // カウンターの更新
    globalCounter++;
    printf("グローバルカウンター: %d\n", globalCounter);
    
    return 0;
}