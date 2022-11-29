#ifndef COLOR_INCLUDE
    #define COLOR_INCLUDE
    
    //颜色饱和度处理
    //_color:颜色值
    //_saturation:饱和度 >=0
    inline half3 ColorSaturation(half3 _color, half _saturation) {
        half luminance = 0.2125 * _color.r + 0.7154 * _color.g + 0.0721 * _color.b;
        half3 luminanceColor = half3(luminance, luminance, luminance);
        return lerp(luminanceColor, _color, _saturation);
    }

    inline half3 Saturation(half3 color, half s)
    {
        half luma = dot(color, half3(0.2126729, 0.7151522, 0.0721750));
        return luma.xxx + s.xxx * (color - luma.xxx);
    }


    inline half LuminanceUE(half3 LinearColor)
    {
        return dot(LinearColor, half3( 0.3, 0.59, 0.11 ));
    }

    half3 ColorBlending(half3 Base, half3 Blend, half Opacity, half BlendFunc)
    {
        // Pin Light
        if (BlendFunc == 0)
        {
            half3 check = step (0.5, Blend);
            half3 result1 = check * max(2.0 * (Base - 0.5), Blend);
            half3 final = result1 + (1.0 - check) * min(2.0 * Base, Blend);
            return lerp(Base, final, Opacity);
        }

        // Soft Light
        else if (BlendFunc == 1)
        {
            half3 result1 = 2.0 * Base * Blend + Base * Base * (1.0 - 2.0 * Blend);
            half3 result2 = sqrt(Base) * (2.0 * Blend - 1.0) + 2.0 * Base * (1.0 - Blend);
            half3 zeroOrOne = step(0.5, Blend);
            half3 final = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
            return lerp(Base, final, Opacity);
        }

        // Lighten
        else if (BlendFunc == 2)
        {
            half3 final = max(Blend, Base);
            return lerp(Base, final, Opacity);
        }
    }

#endif // COLOR_INCLUDE