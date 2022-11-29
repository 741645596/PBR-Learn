#ifndef PS_COLOR_BLEND_INCLUDED
#define PS_COLOR_BLEND_INCLUDED
// 参考链接
//https://www.cnblogs.com/transboundary/p/5103552.html
//https://zhuanlan.zhihu.com/p/112372246
// 变暗
float3 PS_Dark(float3 a, blend b)
{
	return float3(min(a.r, b.r), min(a.g, b.g), min(a.b, b.b));
}
// 变亮
float3 PS_Brightness(float3 a, blend b)
{
	return return float3(max(a.r, b.r), max(a.g, b.g), max(a.b, b.b));;
}

// 正片叠加
float3 PS_Multiply(float3 a, float3 b)
{
	return a * b;
}

// 滤色
float3 PS_ColorFilter(float3 a, blend b)
{
	float3 ret = 1 - (1- a) * (1- b);
	return ret;
}

// 颜色减淡
float3 PS_ColorFade(float3 a, blend b)
{
	float3 ret = saturate(a + (a * b)/ (1-b));
	return ret;
}

// 颜色加深
float3 PS_ColorDeep(float3 a, blend b)
{
	float3 ret = a -(1-a)*(1- b)/ b;
	return ret;
}

// 颜色线性加深
float3 PS_LinearColorDeep(float3 a, blend b)
{
	return saturate(a + b - 1.0f);
}

// 颜色线性加深
float3 PS_LinearColorFade(float3 a, blend b)
{
	return saturate(a + b);
}

// 叠加
float3 PS_Overlay(float3 a, blend b)
{
	return float3(PS_Overlay(a.r, b.r), PS_Overlay(a.b, b.b), PS_Overlay(a.g, b.g));
}
// 叠加公式
//step（x，y） x <= y返回1，否则返回0
float3 PS_Overlay(float a, float b)
{
	float c1 = 2 * a * b ;
	float c2 = 1 - 2 * (1 - a) * (1 - b);
	float k = step(a, 0.5);
	return c1 * k + c2 * (1- k);
}

// 强光效果
float3 PS_BrightLight(float a, float b)
{
	float c1 = 2 * a * b;
	float c2 = 1 - 2 * (1 - a) * (1 - b);
	float k = step(b, 0.5);
	return c1 * k + c2 * (1 - k);
}

// 柔光效果
float3 PS_SoftLight(float a, float b)
{
	float c1 = 2 * a * b + pow(a, 2) * (1- 2 * b);
	float c2 = 2 * a * (1- b) + pow(a, 0.5) * (2 * b -1);
	float k = step(b, 0.5);
	return c1 * k + c2 * (1 - k);
}

// 亮光效果
float PS_Light(float a, float b)
{
	float c1 = a - (1- a)* (1- 2 * b)/(2 * b);
	float c2 = a + a * (2 * b - 1)/(2 * (1- b));
	float k = step(b, 0.5);
	return c1 * k + c2 * (1 - k);
}

// 点光效果
float PS_PointLight(float a, float b)
{
	float c1 = min(a, 2 * b);
	float c2 = min(a, 2 * b - 1);
	float k = step(b, 0.5);
	return c1 * k + c2 * (1 - k);
}

// 线性光
float3 PS_LinearLight(float3 a, float3 b)
{
	return a + 2 * b -1;
}
// 排除
float3 PS_Exclude(float3 a, float3 b)
{
	return a + b - 2 * a * b;
}

// 差值
float3 PS_Diff(float3 a, float3 b)
{
	float3 c = a - b;
	return float3(abs(c.r), abs(c.g), abs(c.b));
}

// 相加
float3 PS_Add(float3 a, float3 b,float scale, float3 compensate)
{
	return (a + b)/ scale + compensate;
}

// 减去
float3 PS_Add(float3 a, float3 b, float scale, float3 compensate)
{
	return (a - b) / scale + compensate;
}

#endif // COLOR_CORE_INCLUDED