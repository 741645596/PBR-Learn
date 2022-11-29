using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class WaterColor : MonoBehaviour
{
    [Header("水的颜色过渡")]
    public Gradient WaterGradient01;
    public Gradient WaterGradient02;

    public Texture2D RampTexture;

    void OnValidate()
    {
        //创建一家纹理图
        RampTexture = new Texture2D(512, 2);
        RampTexture.wrapMode = TextureWrapMode.Clamp;
        RampTexture.filterMode = FilterMode.Bilinear;

        int count = RampTexture.width * RampTexture.height;
        //为纹理图声明相对应相除数量的颜色数组
        Color[] cols = new Color[count];
        for (int i = 0; i < 512; i++)
        {
            cols[i] = WaterGradient01.Evaluate((float)i / 511);
        }
        for (int i = 512; i < 1024; i++)
        {
            cols[i] = WaterGradient02.Evaluate((float)(i - 512) / 511);
        }

        //把颜色应用到纹理上
        RampTexture.SetPixels(cols);
        RampTexture.Apply();

        //全局赋值
        Shader.SetGlobalTexture("_RampTexture", RampTexture);
    }
}
