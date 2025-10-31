local ContentProvider = game:GetService('ContentProvider')

local LoaderService = {}
LoaderService.__index = LoaderService

local service
function LoaderService.new()
  if service then return service end
  local self = setmetatable({}, LoaderService)

  service = self
  return self
end

function LoaderService.PreloadAssets(assetInstances : {Instance}) : nil
  if not assetInstances or typeof(assetInstances) ~= 'table' then warn('Invalid assets provided') return end

  print('loading:, ', #assetInstances)
  ContentProvider:PreloadAsync(assetInstances)
end

local loaderService = LoaderService.new()

return loaderService
