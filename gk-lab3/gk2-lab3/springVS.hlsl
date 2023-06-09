static const float two_pi = 6.283185307179586476925286766559f;
static const float ln_half = -0.693147;

matrix modelMtx, modelInvTMtx, viewProjMtx;
float4 camPos;
float h0, l, r, rsmall;
float time, xmax, vmax, thalf;

struct VSInput
{
	float3 pos : POSITION0;
	float3 norm : NORMAL0;
	float2 tex : TEXCOORD0;
};

struct VSOutput
{
	float4 pos : SV_POSITION;
	float3 worldPos : POSITION0;
	float3 norm : NORMAL0;
	float3 view : VIEWVEC0;
	float2 tex : TEXCOORD0;
	float3 tangent : TANGENT0;
};

float dangle_ds(float l, float r, float h)
{
	return sqrt(l * l - h * h) / r;
}

float3 get_position(float s, float r, float h, float a)
{
	return float3(
		r * cos(s * a), 
		s * h,
		r * sin(s * a));
}

float3 get_tangent(float s, float r, float h, float a)
{
	return float3(
		-r * a * sin(s * a), 
		h,
		r * a * cos(s * a));
}

float3 get_normal(float s, float r, float h, float a)
{
	return float3(
		-r * a * a * cos(s * a), 
		0, 
		-r * a * a * sin(s * a));
}

float springHeight(float t)
{
	return xmax * exp(ln_half * t / thalf) * sin(vmax / xmax * t);
}

VSOutput main(VSInput i)
{
	VSOutput o;

	float h = h0 + springHeight(time);
	float a = dangle_ds(l, r, h);
	float3 CurvePosition = get_position(i.pos.y, r, h, a);
	float3 CurveTangent = normalize(get_tangent(i.pos.y, r, h, a));
	float3 CurveNormal = normalize(get_normal(i.pos.y, r, h, a));
	float3 CurveBinormal = cross(CurveNormal, CurveTangent);
	float3 Normal = CurveNormal * cos(two_pi * i.pos.x) + CurveBinormal * sin(two_pi * i.pos.x);
	float4 Position = float4(CurvePosition + rsmall * Normal, 1.0f);
	
	float4 worldPos = mul(modelMtx, Position);
	o.view = normalize(camPos.xyz - worldPos.xyz);
	o.norm = normalize(mul(modelInvTMtx, float4(Normal, 0.0f)).xyz);
	o.worldPos = worldPos.xyz;
	o.pos = mul(viewProjMtx, worldPos);
	o.tangent = mul(modelInvTMtx, float4(CurveTangent, 0.0f)).xyz;
	o.tex = float2(i.pos.y * 6.8f, i.pos.x * 0.2f);

	return o;
}