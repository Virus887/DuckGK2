float4 camPos;
sampler samp;
textureCUBE envMap;
texture3D perlin;
float time;

struct PSInput
{
	float4 pos : SV_POSITION;
	float3 localPos : POSITION0;
	float3 worldPos : POSITION1;
};

float3 intersectRay(float3 P, float3 R) 
{
	float3 ts = max((-P + 1) / R, (-P - 1) / R);
	float t = min(ts.x, min(ts.y, ts.z));
	return P + t * R;
}

float fresnel(float3 view, float3 norm, float n1, float n2)
{
	float F = pow((n2 - n1) / (n2 + n1), 2);
	float cos = max(dot(norm, view), 0);

	return F + (1-F)*pow(1-cos,5);
}

float4 main(PSInput i) : SV_TARGET
{
	float3 viewVec = normalize(camPos.xyz - i.worldPos);

	float3 tex = float3(i.localPos.xz * 10.0f, time);
	float ex = perlin.Sample(samp, tex).r;
	float ez = perlin.Sample(samp, tex + 0.5f).r;
	ex = 2 * ex - 1;
	ez = 2 * ez - 1;
	float3 norm = normalize(float3(ex, 20.0f, ez));

	float n = 0.75f;
	if (dot(norm, viewVec) < 0)
	{
		norm = -norm;
		n = 1 / n;
	}

	float3 reflected = reflect(-viewVec, norm);
	float3 refracted = refract(-viewVec, norm, n);

	float3 Qr = intersectRay(i.localPos, reflected);
	float3 Qt = intersectRay(i.localPos, refracted);

	float3 colorR = envMap.Sample(samp, Qr).rgb;
	float3 colorT = envMap.Sample(samp, Qt).rgb;
	float f = any(refracted) ?
		fresnel(viewVec, norm, 1, 4.0f / 3.0f) : 1;

	
	float3 color = lerp(colorT, colorR, f);


	color = pow(color, 0.4545f);



	return float4(color, 1.0f);
}