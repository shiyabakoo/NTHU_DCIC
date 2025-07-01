# DCIC Final Project

## Cordic


$$
x_{i+1} = x_i - y_i \cdot d_i \cdot 2^{-i}
$$

$$
y_{i+1} = y_i + x_i \cdot d_i \cdot 2^{-i}
$$

$$
z_{i+1} = z_i - d_i \cdot \tan^{-1}(2^{-i})
$$

Where the direction of rotation \( d_i \) is defined as:

$$
d_i =
\begin{cases}
-1 & \text{if } z_i < 0 \\
+1 & \text{if } z_i > 0
\end{cases}
$$
