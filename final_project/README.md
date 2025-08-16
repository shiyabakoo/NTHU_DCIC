# DCIC Final Project

## Cordic
cordic是一種座標旋轉的數學計算方式, 透過加法、減法、位移、查表來計算三角函數及平方根的方法, 不需要透過乘法和減法, 因此很適合用在硬體設計上


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


當經過多次iteration後

$$
x_{n} = A_{n} \cdot \sqrt{x_{0}^2 + y_{0}^2}
$$

$$
y_{n} = 0
$$

$$
z_{n} = z_{0} + tan^-1(y_{0}/x_{0})
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

當經過多次iteration後

$$
x_{n} = K \cdot (x_{0}cos(z_{0}) - y_{0}sin(z_{0}))
$$

$$
y_{n} = K \cdot (x_{0}sin(z_{0}) + y_{0}cos(z_{0}))
$$

$$
z_{n} = 0
$$

如何利用rotation mode去計算cos、sin:

將初始向量設為

$$
x_{0} = 1
$$

$$
y_{0} = 0
$$

$$
z_{0} = 要計算的cos角度
$$

利用這樣的初始設定, 最終cordic的x乘上K即為cos值、y乘上K即為sin值
### cordic的限制
cordic有旋轉角度上的限制, 由於cordic是透過小幅度旋轉來達到旋轉向量, 當cordic的次數趨近無限大時, 旋轉角度會達到上限, 其範圍限制在±π/2
也就是說當rotation mode的旋轉角度超過範圍或是vector mode的向量不在1、4象限的話就要先另外做處理再做cordic

在vector mode中為了防止向量不在1、4象限中, 會先將向量做correction, 把向量旋轉+π/2或-π/2 

而在rotation mode中, 要先判斷角度(z)是否超過±π/2, 才去做修正

$$
x_{0}、y_{0}、z_{0} 為處理過後的輸入向量及旋轉角度
$$

$$
x_{0} = -d \cdot y_{in}
$$

$$
y_{0} = d \cdot x_{in}
$$

$$
z_{0} = z_{in} - d \cdot \frac{\pi}{2} 
$$

$$
d =
\begin{cases}
-sign(y_{in})& \text {vector mode} \\
sign(z_{in}) & \text {rotation mode}
\end{cases}
$$
