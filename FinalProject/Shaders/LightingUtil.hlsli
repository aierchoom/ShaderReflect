struct Light {
  float3 Strength;
  float FalloffStart;
  float3 Direction;
  float FalloffEnd;
  float3 Position;
  float SpotPower;
};

struct Material {
  float4 DiffuseAlbedo;
  float3 FresnelR0;
  float Shininess;
};

float CalcAttenuation(float d, float falloffStart, float falloffEnd)
{
  return saturate((falloffEnd - d) / (falloffEnd - falloffStart));
}

float3 SchlickFresnel(float3 R0, float3 normal, float3 lightVec)
{
  float cosIncidentAngle = saturate(dot(normal, lightVec));

  float f0              = 1.0f - cosIncidentAngle;
  float3 reflectPercent = R0 + (1.0f - R0) * (f0 * f0 * f0 * f0 * f0);

  return reflectPercent;
}

float3 BlinnPhong(float3 lightStrength, float3 lightVec, float3 normal, float3 toEye, Material mat)
{
  const float m  = mat.Shininess * 256.0f;
  float3 halfVec = normalize(toEye + lightVec);

  float roughnessFactor = (m + 8.0f) * pow(max(dot(halfVec, normal), 0.0f), m) / 8.0f;
  float3 fresnelFactor  = SchlickFresnel(mat.FresnelR0, halfVec, lightVec);

  float3 specAlbedo = fresnelFactor * roughnessFactor;

  // Our spec formula goes outside [0,1] range, but we are
  // doing LDR rendering.  So scale it down a bit.
  specAlbedo = specAlbedo / (specAlbedo + 1.0f);

  return (mat.DiffuseAlbedo.rgb + specAlbedo) * lightStrength;
}

float3 ComputePointLight(Light L, Material mat, float3 pos, float3 normal, float3 toEye)
{
  float3 lightVec = L.Position - pos;

  float d = length(lightVec);

  if (d > L.FalloffEnd) return 0.0f;

  lightVec /= d;

  float ndotl          = max(dot(lightVec, normal), 0.0f);
  float3 lightStrength = L.Strength * ndotl;

  float att = CalcAttenuation(d, L.FalloffStart, L.FalloffEnd);
  lightStrength *= att;

  return BlinnPhong(lightStrength, lightVec, normal, toEye, mat);
}