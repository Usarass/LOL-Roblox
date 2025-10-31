local CameraService = require(game:GetService('ReplicatedStorage').Services.Camera)

print("Reloaded CameraHandler")
CameraService.disable()
CameraService.enable()