# DCIC Final Project

## Cordic
cordicv是一種座標旋轉的數學計算方式, 透過加法、減法、位移、查表來計算三角函數及平方根的方法, 不需要透過乘法和減法, 因此很適合用在硬體設計上


cordic運作的方式有兩種 1.vector mode 2.rotation mode
### vector mode
vector mode是將一個已知向量旋轉到x軸上, 進而得知其長度

$$
x_{i+1} = x_i - y_i \cdot d_i \cdot 2^{-i}
$$

$$
y_{i+1} = y_i + x_i \cdot d_i \cdot 2^{-i}
$$

$$
z_{i+1} = z_i - d_i \cdot \tan^{-1}(2^{-i})
$$

Where the direction of rotation is defined as:

$$
d_i =
\begin{cases}
+1 & \text{if } y_i < 0 \\
-1 & \text{if } y_i > 0
\end{cases}
$$

### rotation mode
rotation mode是給定輸入向量及要旋轉的角度, 將輸入向量旋轉給定的旋轉角度

$$
x_{i+1} = x_i - y_i \cdot d_i \cdot 2^{-i}
$$

$$
y_{i+1} = y_i + x_i \cdot d_i \cdot 2^{-i}
$$

$$
z_{i+1} = z_i - d_i \cdot \tan^{-1}(2^{-i})
$$

Where the direction of rotation is defined as:

$$
d_i =
\begin{cases}
-1 & \text{if } z_i < 0 \\
+1 & \text{if } z_i > 0
\end{cases}
$$
