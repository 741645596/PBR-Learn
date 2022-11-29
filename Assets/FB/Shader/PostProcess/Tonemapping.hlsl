#ifndef TONEMAPPING_INCLUDE
#define TONEMAPPING_INCLUDE

/*
============================================
// Uncharted settings
Slope = 0.63;
Toe = 0.55;
Shoulder = 0.47;
BlackClip= 0;
WhiteClip = 0.01;

// HP settings
Slope = 0.65;
Toe = 0.63;
Shoulder = 0.45;
BlackClip = 0;
WhiteClip = 0;

// Legacy settings
Slope = 0.98;
Toe = 0.3;
Shoulder = 0.22;
BlackClip = 0;
WhiteClip = 0.025;

// ACES settings
Slope = 0.91;
Toe = 0.53;
Shoulder = 0.23;
BlackClip = 0;
WhiteClip = 0.035;
===========================================
*/

float3 Tonemapping_Unity(float3 LinearColor)
{
	float3 aces = ACEScg_to_ACES(LinearColor);
	return AcesTonemap(aces);
}

float3 Tonemapping_Unreal( float3 LinearColor,float FilmSlope,float FilmToe,float FilmShoulder ,float FilmBlackClip,float FilmWhiteClip) 
{
	LinearColor = ACEScg_to_unity(LinearColor);
	const float3x3 AP1_2_AP0 = AP1_2_AP0_MAT;
	
	float3 ColorAP1 = LinearColor;
	float3 ColorAP0 = mul( AP1_2_AP0, ColorAP1 );

	// "Glow" module constants
	const float RRT_GLOW_GAIN = 0.05;
	const float RRT_GLOW_MID = 0.08;

	float saturation = rgb_2_saturation( ColorAP0 );
	float ycIn = rgb_2_yc( ColorAP0 );
	float s = sigmoid_shaper( (saturation - 0.4) / 0.2);
	float addedGlow = 1 + glow_fwd( ycIn, RRT_GLOW_GAIN * s, RRT_GLOW_MID);
	ColorAP0 *= addedGlow;

	// --- Red modifier --- //
	const float RRT_RED_SCALE = 0.82;
	const float RRT_RED_PIVOT = 0.03;
	const float RRT_RED_HUE = 0;
	const float RRT_RED_WIDTH = 135;
	float hue = rgb_2_hue( ColorAP0 );
	float centeredHue = center_hue( hue, RRT_RED_HUE );
	float hueWeight = pow( smoothstep( 0, 1, 1 - abs( 2 * centeredHue / RRT_RED_WIDTH ) ) ,2);
	ColorAP0.r += hueWeight * saturation * (RRT_RED_PIVOT - ColorAP0.r) * (1. - RRT_RED_SCALE);

	// Use ACEScg primaries as working space
	float3 WorkingColor = mul( AP0_2_AP1_MAT, ColorAP0 );
	WorkingColor = max( 0, WorkingColor );

	// Pre desaturate
	WorkingColor = lerp( dot( WorkingColor, AP1_RGB2Y ), WorkingColor, 0.96 );
	
	const float ToeScale			= 1 + FilmBlackClip - FilmToe;
	const float ShoulderScale	= 1 + FilmWhiteClip - FilmShoulder;
	
	const float InMatch = 0.18;
	const float OutMatch = 0.18;

	float ToeMatch;
	if( FilmToe > 0.8 )
	{
		// 0.18 will be on straight segment
		ToeMatch = ( 1 - FilmToe  - OutMatch ) / FilmSlope + log10( InMatch );
	}
	else
	{
		// 0.18 will be on toe segment

		// Solve for ToeMatch such that input of InMatch gives output of OutMatch.
		const float bt = ( OutMatch + FilmBlackClip ) / ToeScale - 1;
		ToeMatch = log10( InMatch ) - 0.5 * log( (1+bt)/(1-bt) ) * (ToeScale / FilmSlope);
	}

	float StraightMatch = ( 1 - FilmToe ) / FilmSlope - ToeMatch;
	float ShoulderMatch = FilmShoulder / FilmSlope - StraightMatch;
	
	float3 LogColor = log10( WorkingColor );
	float3 StraightColor = FilmSlope * ( LogColor + StraightMatch );
	
	float3 ToeColor		= (    -FilmBlackClip ) + (2 *      ToeScale) / ( 1 + exp( (-2 * FilmSlope /      ToeScale) * ( LogColor -      ToeMatch ) ) );
	float3 ShoulderColor	= ( 1 + FilmWhiteClip ) - (2 * ShoulderScale) / ( 1 + exp( ( 2 * FilmSlope / ShoulderScale) * ( LogColor - ShoulderMatch ) ) );

	ToeColor		= LogColor <      ToeMatch ?      ToeColor : StraightColor;
	ShoulderColor	= LogColor > ShoulderMatch ? ShoulderColor : StraightColor;

	float3 t = saturate( ( LogColor - ToeMatch ) / ( ShoulderMatch - ToeMatch ) );
	t = ShoulderMatch < ToeMatch ? 1 - t : t;
	t = (3-2*t)*t*t;
	float3 ToneColor = lerp( ToeColor, ShoulderColor, t );

	// Post desaturate
	ToneColor = lerp( dot( float3(ToneColor), AP1_RGB2Y ), ToneColor, 0.93 );

	// Returning positive AP1 values
	return max( 0, ToneColor );
}




// GT_Tonemap
float W_f(float x,float e0,float e1) {
	if (x <= e0)
		return 0;
	if (x >= e1)
		return 1;
	float a = (x - e0) / (e1 - e0);
	return a * a*(3 - 2 * a);
}
float H_f(float x, float e0, float e1) {
	if (x <= e0)
		return 0;
	if (x >= e1)
		return 1;
	return (x - e0) / max((e1 - e0), HALF_MIN);
}

float GranTurismoTonemapper(float x)
{
	const float e = 2.71828;

	float P = 1;
	float a = 1;
	float m = 0.22;
	float l = 0.4;
	float c = 1.33;
	float b = 0;
	float l0 = (P - m)*l / a;
	float L0 = m - m / a;
	float L1 = m + (1 - m) / a;
	float L_x = m + a * (x - m);
	float T_x = m * pow(x / m, c) + b;
	float S0 = m + l0;
	float S1 = m + a * l0;
	float C2 = a * P / (P - S1);
	float S_x = P - (P - S1)*pow(e,-(C2*(x-S0)/P));
	float w0_x = 1 - W_f(x, 0, m);
	float w2_x = H_f(x, m + l0, m + l0);
	float w1_x = 1 - w0_x - w2_x;
	float f_x = T_x * w0_x + L_x * w1_x + S_x * w2_x;
	return f_x;
}

float3 Tonemapping_GT(float3 LinearColor)
{
	float r = GranTurismoTonemapper(LinearColor.r);
	float g = GranTurismoTonemapper(LinearColor.g);
	float b = GranTurismoTonemapper(LinearColor.b);
	return float3(r, g, b);
}

#endif // TONEMAPPING_INCLUDE