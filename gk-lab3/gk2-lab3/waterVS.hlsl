matrix modelMtx, viewProjMtx;
float waterLevel;

struct VSOutput
{
	float4 pos : SV_POSITION;
	float3 localPos : POSITION0;
	float3 worldPos : POSITION1;
};

VSOutput main(float3 pos : POSITION0)
{
	VSOutput o;
	pos.y = waterLevel;
	o.localPos = pos;

	o.worldPos = mul(modelMtx, float4(pos, 1.0f));
	o.pos = mul(viewProjMtx, mul(modelMtx, float4(pos,1.0f)));

	return o;
}