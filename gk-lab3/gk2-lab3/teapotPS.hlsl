#define NLIGHTS 2
static const float PI = 3.14159265f;
static const float EPS = 0.0000001f;


SamplerState samp : register(s0);
Texture2D normTex : register(t0);
Texture2D albedoTex : register(t1);
Texture2D metallicTex : register(t2);
Texture2D normalTex : register(t3);
Texture2D roughnessTex : register(t4);

float4 lightPos[NLIGHTS];
float3 lightColor[NLIGHTS];

//Part 7
TextureCube irMap;
TextureCube pfEnvMap;
Texture2D brdfTex;


float3 normalMapping(float3 N, float3 T, float3 tn)
{
	float3 B = normalize(cross(N, T));
	T = cross(B, N);
	float3x3 mat = {
		T.x,B.x,N.x,
		T.y,B.y,N.y,
		T.z,B.z,N.z,
	};
	return mul(mat, tn);
}

float normalDistributionGGX(float3 norm, float3 h, float roughness)
{
	float r2 = roughness * roughness;
	return r2 / (PI * pow( pow(max(dot(norm,h), EPS),2.0f) * (r2-1.0f)+1.0f, 2.0f));
}

float geometrySchlickGGX(float a, float roughness)
{
	float q = pow(roughness + 1.0f, 2.0f) / 8.0f;
	return a / (a * (1.0f - q) + q);

}

float geometrySmith(float3 n, float3 l, float3 v, float roughness)
{
	float gsNL = geometrySchlickGGX(max(dot(n, l), EPS), roughness);
	float gsNV = geometrySchlickGGX(max(dot(n, v), EPS), roughness);
	return gsNV * gsNL;
}

float3 fresnel(float3 F0, float3 n, float3 l)
{
	return F0 + (1.0f - F0) * pow(1.0f - dot(n, l), 5.0f);
}

//Part7
float3 fresnelSchlickRoughness(float cosTheta, float3 F0, float r)
{
	return F0 + clamp((1 - r) - F0, 0, 1) * pow(1 - cosTheta, 5.0f);
}

struct PSInput
{
	float4 pos : SV_POSITION;
	float3 worldPos : POSITION0;
	float3 norm : NORMAL0;
	float3 view : VIEWVEC0;
	float2 tex : TEXCOORD0;
};

float4 main(PSInput i) : SV_TARGET
{
	float3 N = normalize(i.norm);
	float3 dPdx = ddx(i.worldPos);
	float3 dPdy = ddy(i.worldPos);
	float2 dtdx = ddx(i.tex);
	float2 dtdy = ddy(i.tex);
	float3 T = normalize(-dPdx * dtdy.y + dPdy * dtdx.y);

	float3 tn = normalTex.Sample(samp, i.tex)*2.0f - float3(1.0f,1.0f,1.0f);
	float3 norm = normalMapping(N, T, tn);

	float3 albedo = albedoTex.Sample(samp, i.tex);
	float3 metallic = metallicTex.Sample(samp, i.tex);
	float3 roughness = roughnessTex.Sample(samp, i.tex);

	float3 A = pow(albedo, 2.2f);
	float3 F0 = A * metallic + (1.0f - metallic) * 0.04f;

	float3 I = 0;
	for (int k = 0; k < 2; k++)
	{
		float3 l = normalize(lightPos[k] - i.worldPos);
		float3 L = lightColor[k] * max(dot(norm, l), 0.0f) / pow(length(lightPos[k] - i.worldPos), 2.0f);

		float3 h = normalize(i.view + l);
		float NDF = normalDistributionGGX(norm, h, roughness);
		float G = geometrySmith(norm, i.view, l, roughness);
		//PART7 - fresnel(F0,h,l) instead of fresnel(F0,norm,l) fix
		float3 kd = (1.0f - fresnel(F0, h, l)) * (1.0f -metallic);

		float3 fct = fresnel(F0, h, l) * NDF * G / (4.0f *
				max(dot(norm, i.view), EPS) *
				max(dot(norm, l), EPS)
			);
		float3 brdf = kd * A / PI + fct;
		I += brdf *L;


	}

	////Part7
	float3 Iir = irMap.Sample(samp, norm).rgb;
	float3 ks = fresnelSchlickRoughness(max(dot(norm,i.view),0.0f),F0, roughness.x);
	//float3 kd2 = (1.0f - fresnel(F0, norm, i.view)) * (1.0f - metallic);
	float3 kd2 = (1.0f - ks) * (1.0f - metallic);
	float3 Id = kd2 * A * Iir;	//swiatlo rozproszone

	float3 R = reflect(-i.view, norm);
	float3 Ii = pfEnvMap.SampleLevel(samp, R, roughness.x * 6.0f).rgb;
	float2 brdf2 = brdfTex.Sample(samp, float2(max(dot(norm, i.view), 0.0f), roughness.x)).rg;	//r -> fm, g-> f0
	float3 Is = Ii * (F0*brdf2.r+brdf2.g);
	float3 color = I + Id + Is;
	color = color / (color + 1);

	return  float4(pow(color, 0.4545f), 1.0f);
	//return  float4(pow(0.03f * A + I+Id+Is, 0.4545f), 1.0f);
}