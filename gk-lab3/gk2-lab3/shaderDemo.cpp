#include "shaderDemo.h"

using namespace mini;
using namespace gk2;
using namespace DirectX;
using namespace std;
using namespace directx;
using namespace utils;

ShaderDemo::ShaderDemo(HINSTANCE hInst): GK2ShaderDemoBase(hInst)
{
	//Shader Variables
	m_variables.AddSemanticVariable("modelMtx", VariableSemantic::MatM);
	m_variables.AddSemanticVariable("modelInvTMtx", VariableSemantic::MatMInvT);
	m_variables.AddSemanticVariable("viewProjMtx", VariableSemantic::MatVP);
	m_variables.AddSemanticVariable("camPos", VariableSemantic::Vec4CamPos);

	XMFLOAT4 lightPos[2] = {
		{ -1.f, 0.0f, -3.5f, 1.f },
		{ 0.f, 3.5f, 0.0f, 1.f } };
	XMFLOAT3 lightColor[2] = {
	{ 12.f, 9.f, 10.f },
	{ 1.f, 0.f, 30.f } };
	m_variables.AddGuiVariable("lightPos",
		lightPos, -10, 10);
	m_variables.AddGuiVariable("lightColor",
		lightColor, 0, 100, 1);
	m_variables.AddGuiVariable("m", 50.f, 10.f, 200.f);
	
	auto h0 = 1.5f;
	m_variables.AddGuiVariable("h0", h0, 0, 3);
	m_variables.AddGuiVariable("l", 15.f, 5, 25);
	m_variables.AddGuiVariable("r", 0.5f, 0.01f, 1);
	m_variables.AddGuiVariable("rsmall",0.1f, 0.01f, 0.5f);

	m_variables.AddGuiVariable("thalf", 3.f, 1.f, 5.f);
	m_variables.AddGuiVariable("xmax", .5f, .1f, 1.f);
	m_variables.AddGuiVariable("vmax", 4.f, .5f, 10.f);
	m_variables.AddSemanticVariable("time", VariableSemantic::FloatT);

	m_variables.AddSampler(m_device, "samp");
	m_variables.AddTexture(m_device, "normTex",
		L"textures/normal1.png"); 
	m_variables.AddTexture(m_device, "envMap",
			L"textures/cubeMap.dds");
	m_variables.AddTexture(m_device, "perlin",
		L"textures/NoiseVolume.dds");
	m_variables.AddTexture(m_device, "albedoTex",
		L"textures/rustediron2_basecolor.png");
	m_variables.AddTexture(m_device, "metallicTex",
		L"textures/rustediron2_metallic.png");
	m_variables.AddTexture(m_device, "normalTex",
		L"textures/rustediron2_normal.png");
	m_variables.AddTexture(m_device, "roughnessTex",
		L"textures/rustediron2_roughness.png");

	m_variables.AddTexture(m_device, "irMap", 
		L"textures/cubeMapIrradiance.dds");
	m_variables.AddTexture(m_device, "pfEnvMap", 
		L"textures/cubeMapRadiance.dds");
	m_variables.AddTexture(m_device, "brdfTex", 
		L"textures/brdf_lut.png");

	m_variables.AddSemanticVariable("mvpMtx",
		VariableSemantic::MatMVP);
	m_variables.AddGuiVariable("waterLevel",
		-0.05f, -1, 1, 0.001f);

	//Models
	XMFLOAT4X4 modelMtx;
	const auto sphere = addModelFromString("s 0 0 0 0.5");
	const auto teapot = addModelFromFile("models/Teapot.3ds");
	XMStoreFloat4x4(&modelMtx,
		XMMatrixScaling(1 / 60.0f, 1 / 60.0f, 1 / 60.0f) *
		XMMatrixRotationX(-XM_PIDIV2) *
		XMMatrixTranslation(0, 0.5f-h0, 0));
	model(teapot).applyTransform(modelMtx);

	//const auto duck = addModelFromFile("models/Teapot.3ds");
	//XMStoreFloat4x4(&modelMtx,
	//	XMMatrixScaling(1 / 60.0f, 1 / 60.0f, 1 / 60.0f) *
	//	XMMatrixRotationX(-XM_PIDIV2) *
	//	XMMatrixTranslation(0, 0.5f - h0, 0));
	//model(duck).applyTransform(modelMtx);


	const auto plane = addModelFromFile("models/Plane.obj");
	XMStoreFloat4x4(&modelMtx, XMMatrixTranslation(0, -h0, 0));
	model(plane).applyTransform(modelMtx);

	auto quad = addModelFromString(
		"pp 4\n1 0 1 0 1 0\n1 0 -1 0 1 0\n"
		"-1 0 -1 0 1 0\n-1 0 1 0 1 0\n");
	auto envModel =
		addModelFromString("hex 0 0 0 1.73205");
	XMStoreFloat4x4(&modelMtx,
		XMMatrixScaling(20, 20, 20));
	model(quad).applyTransform(modelMtx);
	model(envModel).applyTransform(modelMtx);

	//Render Passes
	const auto passSphere = addPass(L"sphereVS.cso", L"spherePS.cso");

	const auto passTeapot = addPass(L"teapotVS.cso", L"teapotPS.cso");

	const auto passTeapot = addPass(L"duckVS.cso", L"duckPS.cso");


	auto passSpring = addPass(L"springVS.cso",L"springPS.cso");
	auto passEnv = addPass(L"envVS.cso", L"envPS.cso");



	addModelToPass(passTeapot, teapot);
	addModelToPass(passSpring, plane);

	addModelToPass(passEnv, envModel);
	addRasterizerState(passEnv,
		rasterizer_info(true));

	auto passWater =
		addPass(L"waterVS.cso", L"waterPS.cso");
	addModelToPass(passWater, quad);
	rasterizer_info rs;
	rs.CullMode = D3D11_CULL_NONE;
	addRasterizerState(passWater, rs);














}
