static const float ln_half = -0.693147; 

matrix modelMtx, modelInvTMtx, viewProjMtx;
float4 camPos;
float h0;
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
};

float springHeight(float t)
{
	return xmax * exp(ln_half * t / thalf) * sin(vmax / xmax * t);
}

VSOutput main(VSInput i)
{
	VSOutput o;
	float4 worldPos = mul(modelMtx, float4(i.pos, 1.0f));
	worldPos.y += h0 + springHeight(time);
	o.view = normalize(camPos.xyz - worldPos.xyz);
	o.norm = normalize(mul(modelInvTMtx, float4(i.norm, 0.0f)).xyz);
	o.worldPos = worldPos.xyz;
	o.pos = mul(viewProjMtx, worldPos);
	o.tex = i.tex / 4.0f;
	return o;
}