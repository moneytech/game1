
LibOVR :: #foreign_library "../run_tree/LibOVR_out";

// C API

ovrBool  :: s8;
ovrFalse :: 0;
ovrTrue  :: 1;


// @Align(4)
ovrColorf :: struct {
    r, g, b, a: float;
};

// @Align(4)
ovrVector2i :: struct {
    x, y: s32;
};

// @Align(4)
ovrSizei :: struct {
    w, h: s32;
};

// @Align(4)
ovrRecti :: struct {
    Pos: ovrVector2i;
    Size: ovrSizei;
};

make_Recti :: (x: s32, y: s32, w: s32, h: s32) -> ovrRecti {
    o: ovrRecti = ---;
    o.Pos.x = x;
    o.Pos.y = y;
    o.Size.w = w;
    o.Size.h = h;
    return o;
}

// @Align(4)
ovrQuatf :: struct {
    x, y, z, w: float;
};

// @Align(4)
ovrVector2f :: struct {
    x, y: float;
};

// @Align(4)
ovrVector3f :: struct {
    x, y, z: float;
};

// @Align(4)
ovrVector4f :: struct {
    x, y, z, w: float;
};

// @Align(4)
ovrMatrix4f :: struct {
    M: [4][4] float;
};

// @Align(4)
ovrPosef :: struct {
    Orientation: ovrQuatf;
    Position: ovrVector3f;
};


// @Align(8)
ovrPoseStatef :: struct {
    ThePose: ovrPosef;
    AngularVelocity: ovrVector3f;
    LinearVelocity: ovrVector3f;
    AngularAcceleration: ovrVector3f;
    LinearAcceleration: ovrVector3f;
    pad0: [4] u8;
    TimeInSeconds: float64;
};

// @Align(4)
ovrFovPort :: struct {
    UpTan: float;
    DownTan: float;
    LeftTan: float;
    RightTan: float;
};

using ovrHmdType :: enum s32 {
    ovrHmd_None :: 0;
    ovrHmd_DK1 :: 3;
    ovrHmd_DKHD :: 4;
    ovrHmd_DK2 :: 6;
    ovrHmd_CB :: 8;
    ovrHmd_Other :: 9;
    ovrHmd_E3_2015 :: 10;
    ovrHmd_ES06 :: 11;
    ovrHmd_ES09 :: 12;
    ovrHmd_ES11 :: 13;
    ovrHmd_CV1 :: 14;

    ovrHmd_EnumSize :: 0x7fffffff;
};

/// HMD capability bits reported by device.
///
using ovrHmdCaps :: enum s32 {
    ovrHmdCap_DebugDevice :: 0x0010;
    ovrHmdCap_EnumSize :: 0x7fffffff;
};


using ovrTrackingCaps :: enum s32 {
    ovrTrackingCap_Orientation :: 0x0010;
    ovrTrackingCap_MagYawCorrection :: 0x0020;
    ovrTrackingCap_Position :: 0x0040;
    ovrTrackingCap_EnumSize :: 0x7fffffff;
};

/// Optional extensions
using ovrExtensions :: enum s32 {
    ovrExtension_TextureLayout_Octilinear :: 0;
    ovrExtension_Count;
    ovrExtension_EnumSize :: 0x7fffffff;
};

using ovrEyeType :: enum s32 {
    ovrEye_Left :: 0;
    ovrEye_Right :: 1;
    ovrEye_Count :: 2;
    ovrEye_EnumSize :: 0x7fffffff;
};

using ovrTrackingOrigin :: enum s32 {
    ovrTrackingOrigin_EyeLevel :: 0;
    ovrTrackingOrigin_FloorLevel :: 1;
    ovrTrackingOrigin_Count :: 2;
    ovrTrackingOrigin_EnumSize :: 0x7fffffff;
};

// @Align(size_of(*void))
ovrGraphicsLuid :: struct {
    union {
        ptr: *void; // for alignment
        Reserved: [8] u8;
    }
};

// @Align(size_of(*void))
ovrHmdDesc :: struct {
    Type: ovrHmdType;
    pad0: [4] u8;
    ProductName: [64] u8;
    Manufacturer: [64] u8;
    VendorId: s16;
    ProductId: s16;
    SerialNumber: [24] u8;
    FirmwareMajor: s16;
    FirmwareMinor: s16;
    AvailableHmdCaps: u32;
    DefaultHmdCaps: u32;
    AvailableTrackingCaps: u32;
    DefaultTrackingCaps: u32;
    DefaultEyeFov: [ovrEye_Count] ovrFovPort;
    MaxEyeFov: [ovrEye_Count] ovrFovPort;
    Resolution: ovrSizei;
    DisplayRefreshRate: float;
    pad1: [4] u8;
};

ovrHmdStruct :: struct {}; // opaque
ovrSession :: *ovrHmdStruct;

#if OS_WINDOWS {
    ovrProcessId :: u32;
} else {
    ovrProcessId :: pid_t;
}

using ovrStatusBits :: enum s32 {
    ovrStatus_OrientationTracked :: 0x0001;
    ovrStatus_PositionTracked :: 0x0002;
    ovrStatus_EnumSize :: 0x7fffffff;
};

// @Align(size_of(*void))
ovrTrackerDesc :: struct {
    alignment: *void;
    #place alignment;

    FrustumHFovInRadians: float;
    FrustumVFovInRadians: float;
    FrustumNearZInMeters: float;
    FrustumFarZInMeters: float;
};


using ovrTrackerFlags :: enum {
    ovrTracker_Connected :: 0x0020;
    ovrTracker_PoseTracked :: 0x0004;
};

// @Align(8)
ovrTrackerPose :: struct {
    alignment: *void;
    #place alignment;

    TrackerFlags: u32;
    Pose: ovrPosef;
    LeveledPose: ovrPosef;
    pad0: [4] u8;
};

// @Align(8)
ovrTrackingState :: struct {
    HeadPose: ovrPoseStatef;
    StatusFlags: ovrStatusBits;
    HandPoses: [2] ovrPoseStatef;
    HandStatusFlags: [2] u32;
    CalibratedOrigin: ovrPosef;
};


// @Align(4)
ovrEyeRenderDesc :: struct {
    Eye: ovrEyeType;
    Fov: ovrFovPort;
    DistortedViewport: ovrRecti;
    PixelsPerTanAngleAtCenter: ovrVector2f;
    HmdToEyePose: ovrPosef;
};

// @Align(4)
ovrTimewarpProjectionDesc :: struct {
    Projection22: float;
    Projection23: float;
    Projection32: float;
};

// @Align(4)
ovrViewScaleDesc :: struct {
    HmdToEyePose: [ovrEye_Count] ovrPosef;
    HmdSpaceToWorldScaleInMeters: float;
};


using ovrTextureType :: enum s32 {
  ovrTexture_2D;
  ovrTexture_2D_External;
  ovrTexture_Cube;
  ovrTexture_Count;
  ovrTexture_EnumSize :: 0x7fffffff;
};

using ovrTextureBindFlags :: enum s32 {
    ovrTextureBind_None;
    ovrTextureBind_DX_RenderTarget :: 0x0001;
    ovrTextureBind_DX_UnorderedAccess :: 0x0002;
    ovrTextureBind_DX_DepthStencil :: 0x0004;
    ovrTextureBind_EnumSize :: 0x7fffffff;
};

using ovrTextureFormat :: enum s32 {
    OVR_FORMAT_UNKNOWN :: 0;
    OVR_FORMAT_B5G6R5_UNORM :: 1;
    OVR_FORMAT_B5G5R5A1_UNORM :: 2;
    OVR_FORMAT_B4G4R4A4_UNORM :: 3;
    OVR_FORMAT_R8G8B8A8_UNORM :: 4;
    OVR_FORMAT_R8G8B8A8_UNORM_SRGB :: 5;
    OVR_FORMAT_B8G8R8A8_UNORM :: 6;
    OVR_FORMAT_B8G8R8_UNORM :: 27;
    OVR_FORMAT_B8G8R8A8_UNORM_SRGB :: 7;
    OVR_FORMAT_B8G8R8X8_UNORM :: 8;
    OVR_FORMAT_B8G8R8X8_UNORM_SRGB :: 9;
    OVR_FORMAT_R16G16B16A16_FLOAT :: 10;
    OVR_FORMAT_R11G11B10_FLOAT :: 25;
    OVR_FORMAT_D16_UNORM :: 11;
    OVR_FORMAT_D24_UNORM_S8_UINT :: 12;
    OVR_FORMAT_D32_FLOAT :: 13;
    OVR_FORMAT_D32_FLOAT_S8X24_UINT :: 14;
    OVR_FORMAT_BC1_UNORM :: 15;
    OVR_FORMAT_BC1_UNORM_SRGB :: 16;
    OVR_FORMAT_BC2_UNORM :: 17;
    OVR_FORMAT_BC2_UNORM_SRGB :: 18;
    OVR_FORMAT_BC3_UNORM :: 19;
    OVR_FORMAT_BC3_UNORM_SRGB :: 20;
    OVR_FORMAT_BC6H_UF16 :: 21;
    OVR_FORMAT_BC6H_SF16 :: 22;
    OVR_FORMAT_BC7_UNORM :: 23;
    OVR_FORMAT_BC7_UNORM_SRGB :: 24;
    OVR_FORMAT_LAST;
    OVR_FORMAT_ENUMSIZE :: 0x7fffffff;
};

using ovrTextureFlags :: enum s32 {
    ovrTextureMisc_None;
    ovrTextureMisc_DX_Typeless :: 0x0001;
    ovrTextureMisc_AllowGenerateMips :: 0x0002;
    ovrTextureMisc_ProtectedContent :: 0x0004;
    ovrTextureMisc_AutoGenerateMips :: 0x0008;
    ovrTextureMisc_EnumSize :: 0x7fffffff;
};

ovrTextureSwapChainDesc :: struct {
    Type: ovrTextureType;
    Format: ovrTextureFormat;
    ArraySize: s32;
    Width: s32;
    Height: s32;
    MipLevels: s32;
    SampleCount: s32;
    StaticImage: ovrBool;
    MiscFlags: u32; // @Align(4)
    BindFlags: u32; // @Align(4)
};

using ovrMirrorOptions :: enum s32 {
    ovrMirrorOption_Default :: 0x0000;
    ovrMirrorOption_PostDistortion :: 0x0001;
    ovrMirrorOption_LeftEyeOnly :: 0x0002;
    ovrMirrorOption_RightEyeOnly :: 0x0004;
    ovrMirrorOption_IncludeGuardian :: 0x0008;
    ovrMirrorOption_IncludeNotifications :: 0x0010;
    ovrMirrorOption_IncludeSystemGui :: 0x0020;
    ovrMirrorOption_EnumSize :: 0x7fffffff;
};

ovrMirrorTextureDesc :: struct {
    Format: ovrTextureFormat;
    Width: s32;
    Height: s32;
    MiscFlags: u32;
    MirrorOptions: u32;
};

// opaque ? The docs don't specify if these are supposed to be user accesible but I can't find the declarations for these
ovrTextureSwapChainData :: struct {};
ovrMirrorTextureData :: struct {};

ovrTextureSwapChain :: *ovrTextureSwapChainData;
ovrMirrorTexture :: *ovrMirrorTextureData;

ovrViewportStencilType :: enum s32 {
    ovrViewportStencil_HiddenArea :: 0;
    ovrViewportStencil_VisibleArea :: 1;
    ovrViewportStencil_BorderLine :: 2;
    ovrViewportStencilType_EnumSize :: 0x7fffffff;
};

ovrViewportStencilDesc :: struct {
    StencilType: ovrViewportStencilType;
    Eye: ovrEyeType;
    FovPort: ovrFovPort;
    HmdToEyeRotation: ovrQuatf;
};

ovrViewportStencilMeshBuffer :: struct {
    AllocVertexCount: s32;
    UsedVertexCount: s32;
    VertexBuffer: *ovrVector2f;

    AllocIndexCount: s32;
    UsedIndexCount: s32;
    IndexBuffer: *u16;
};

using ovrButton :: enum s32 {
    ovrButton_A :: 0x00000001;
    ovrButton_B :: 0x00000002;
    ovrButton_RThumb :: 0x00000004;
    ovrButton_RShoulder :: 0x00000008;
    ovrButton_X :: 0x00000100;
    ovrButton_Y :: 0x00000200;
    ovrButton_LThumb :: 0x00000400;
    ovrButton_LShoulder :: 0x00000800;
    ovrButton_Up :: 0x00010000;
    ovrButton_Down :: 0x00020000;
    ovrButton_Left :: 0x00040000;
    ovrButton_Right :: 0x00080000;
    ovrButton_Enter :: 0x00100000;
    ovrButton_Back :: 0x00200000;
    ovrButton_VolUp :: 0x00400000;
    ovrButton_VolDown :: 0x00800000;
    ovrButton_Home :: 0x01000000;
    ovrButton_Private :: ovrButton_VolUp | ovrButton_VolDown | ovrButton_Home;
    ovrButton_RMask :: ovrButton_A | ovrButton_B | ovrButton_RThumb | ovrButton_RShoulder;
    ovrButton_LMask :: ovrButton_X | ovrButton_Y | ovrButton_LThumb | ovrButton_LShoulder | ovrButton_Enter;
    ovrButton_EnumSize :: 0x7fffffff;
};

using ovrTouch :: enum s32 {
    // ovrTouch_A :: ovrButton_A;
    // ovrTouch_B :: ovrButton_B;
    // ovrTouch_RThumb :: ovrButton_RThumb;
    // ovrTouch_RThumbRest :: 0x00000008;
    // ovrTouch_RIndexTrigger :: 0x00000010;
    // ovrTouch_RButtonMask :: cast(ovrTouch) (ovrTouch_A | ovrTouch_B) | ovrTouch_RThumb | ovrTouch_RThumbRest | ovrTouch_RIndexTrigger;
    // ovrTouch_X :: ovrButton_X;
    // ovrTouch_Y :: ovrButton_Y;
    // ovrTouch_LThumb :: ovrButton_LThumb;
    // ovrTouch_LThumbRest :: 0x00000800;
    // ovrTouch_LIndexTrigger :: 0x00001000;
    // ovrTouch_LButtonMask :: cast(ovrTouch) (ovrTouch_X | ovrTouch_Y) | ovrTouch_LThumb | ovrTouch_LThumbRest | ovrTouch_LIndexTrigger;
    // ovrTouch_RIndexPointing :: 0x00000020;
    // ovrTouch_RThumbUp :: 0x00000040;
    // ovrTouch_LIndexPointing :: 0x00002000;
    // ovrTouch_LThumbUp :: 0x00004000;
    // ovrTouch_RPoseMask :: ovrTouch_RIndexPointing | ovrTouch_RThumbUp;
    // ovrTouch_LPoseMask :: ovrTouch_LIndexPointing | ovrTouch_LThumbUp;
    ovrTouch_EnumSize :: 0x7fffffff;
};

// @Align(size_of(*void))
ovrTouchHapticsDesc :: struct {
    alignment: *void;
    #place alignment;

    SampleRateHz: s32;
    SampleSizeInBytes: s32;
    QueueMinSizeToAvoidStarvation: s32;
    SubmitMinSamples: s32;
    SubmitMaxSamples: s32;
    SubmitOptimalSamples: s32;
};

// @FixMe this should be s32
using ovrControllerType :: enum u32 {
    ovrControllerType_None :: 0x0000;
    ovrControllerType_LTouch :: 0x0001;
    ovrControllerType_RTouch :: 0x0002;
    ovrControllerType_Touch :: (ovrControllerType_LTouch | ovrControllerType_RTouch);
    ovrControllerType_Remote :: 0x0004;
    ovrControllerType_XBox :: 0x0010;
    ovrControllerType_Object0 :: 0x0100;
    ovrControllerType_Object1 :: 0x0200;
    ovrControllerType_Object2 :: 0x0400;
    ovrControllerType_Object3 :: 0x0800;
    ovrControllerType_Active   :: 0xffffffff;
    ovrControllerType_EnumSize :: 0x7fffffff;
};

using ovrHapticsBufferSubmitMode :: enum {
  ovrHapticsBufferSubmit_Enqueue;
};

OVR_HAPTICS_BUFFER_SAMPLES_MAX :: 256;

ovrHapticsBuffer :: struct {
    Samples: *void;
    SamplesCount: s32;
    SubmitMode: ovrHapticsBufferSubmitMode;
};

ovrHapticsPlaybackState :: struct {
    RemainingQueueSpace: s32;
    SamplesQueued: s32;
};

using ovrTrackedDeviceType :: enum {
    ovrTrackedDevice_None :: 0x0000;
    ovrTrackedDevice_HMD :: 0x0001;
    ovrTrackedDevice_LTouch :: 0x0002;
    ovrTrackedDevice_RTouch :: 0x0004;
    ovrTrackedDevice_Touch :: (ovrTrackedDevice_LTouch | ovrTrackedDevice_RTouch);

    ovrTrackedDevice_Object0 :: 0x0010;
    ovrTrackedDevice_Object1 :: 0x0020;
    ovrTrackedDevice_Object2 :: 0x0040;
    ovrTrackedDevice_Object3 :: 0x0080;

    ovrTrackedDevice_All :: 0xFFFF;
};

using ovrBoundaryType :: enum {
    ovrBoundary_Outer :: 0x0001;
    ovrBoundary_PlayArea :: 0x0100;
};

ovrBoundaryLookAndFeel :: struct {
    Color: ovrColorf;
};

ovrBoundaryTestResult :: struct {
    IsTriggering: ovrBool;
    ClosestDistance: float;
    ClosestPoint: ovrVector3f;
    ClosestPointNormal: ovrVector3f;
};

using ovrHandType :: enum s32 {
    ovrHand_Left :: 0;
    ovrHand_Right :: 1;
    ovrHand_Count :: 2;
    ovrHand_EnumSize :: 0x7fffffff;
};

ovrInputState :: struct {
    TimeInSeconds: float64;
    Buttons: u32;
    Touches: u32;
    IndexTrigger: [ovrHand_Count] float;
    HandTrigger: [ovrHand_Count] float;
    Thumbstick: [ovrHand_Count] ovrVector2f ;
    ControllerType: ovrControllerType;
    IndexTriggerNoDeadzone: [ovrHand_Count] float;
    HandTriggerNoDeadzone: [ovrHand_Count] float;
    ThumbstickNoDeadzone: [ovrHand_Count] ovrVector2f;
    IndexTriggerRaw: [ovrHand_Count] float;
    HandTriggerRaw: [ovrHand_Count] float;
    ThumbstickRaw: [ovrHand_Count] ovrVector2f;
};

ovrCameraIntrinsics :: struct {
    LastChangedTime: float64;
    FOVPort: ovrFovPort;
    VirtualNearPlaneDistanceMeters: float;
    VirtualFarPlaneDistanceMeters: float;
    ImageSensorPixelResolution: ovrSizei;
    LensDistortionMatrix: ovrMatrix4f;
    ExposurePeriodSeconds: float64;
    ExposureDurationSeconds: float64;
};

using ovrCameraStatusFlags :: enum s32 {
    ovrCameraStatus_None :: 0x0;
    ovrCameraStatus_Connected :: 0x1;
    ovrCameraStatus_Calibrating :: 0x2;
    ovrCameraStatus_CalibrationFailed :: 0x4;
    ovrCameraStatus_Calibrated :: 0x8;
    ovrCameraStatus_Capturing :: 0x10;
    ovrCameraStatus_EnumSize :: 0x7fffffff;
};

ovrCameraExtrinsics :: struct {
    LastChangedTimeSeconds: float64;
    CameraStatusFlags: u32;
    AttachedToDevice: ovrTrackedDeviceType;
    RelativePose: ovrPosef;
    LastExposureTimeSeconds: float64;
    ExposureLatencySeconds: float64;
    AdditionalLatencySeconds: float64;
};

OVR_MAX_EXTERNAL_CAMERA_COUNT :: 16;
OVR_EXTERNAL_CAMERA_NAME_SIZE :: 32;

ovrExternalCamera :: struct {
    Name: [OVR_EXTERNAL_CAMERA_NAME_SIZE] u8;
    Intrinsics: ovrCameraIntrinsics;
    Extrinsics: ovrCameraExtrinsics;
};

using ovrInitFlags :: enum s32 {
    ovrInit_Debug :: 0x00000001;
    ovrInit_RequestVersion :: 0x00000004;
    ovrInit_Invisible :: 0x00000010;
    ovrInit_MixedRendering :: 0x00000020;
    ovrInit_FocusAware :: 0x00000040;
    ovrinit_WritableBits :: 0x00ffffff;
    ovrInit_EnumSize :: 0x7fffffff;
};

using ovrLogLevel :: enum s32 {
    ovrLogLevel_Debug :: 0;
    ovrLogLevel_Info :: 1;
    ovrLogLevel_Error :: 2;
    ovrLogLevel_EnumSize :: 0x7fffffff;
};

ovrLogCallback :: #type (userData: *void, level: s32, message: *u8) -> void;

// @Align(8)
ovrInitParams :: struct {
    alignment: *void; #place alignment;

    Flags: u32;
    RequestedMinorVersion: u32;
    LogCallback: ovrLogCallback;
    UserData: *void;
    ConnectionTimeoutMS: u32;
    pad0: [4] u8;
};

ovr_Initialize :: (params: *ovrInitParams) -> ovrResult #foreign LibOVR;
ovr_Shutdown :: () #foreign LibOVR;
ovr_GetLastErrorInfo :: (errorInfo: *ovrErrorInfo) #foreign LibOVR;
ovr_GetVersionString :: () -> *u8 #foreign LibOVR;
ovr_TraceMessage :: (level: s32, message: *u8) -> s32 #foreign LibOVR;
ovr_IdentifyClient :: (identity: *u8) -> ovrResult #foreign LibOVR;
ovr_GetHmdDesc :: (session: ovrSession) -> ovrHmdDesc #foreign LibOVR;
ovr_GetTrackerCount :: (session: ovrSession) -> u32 #foreign LibOVR;
ovr_GetTrackerDesc :: (session: ovrSession, trackerDescIndex: u32) -> ovrTrackerDesc #foreign LibOVR;
ovr_Create :: (session: *ovrSession, luid: *ovrGraphicsLuid) -> ovrResult #foreign LibOVR;
ovr_Destroy :: (session: ovrSession) #foreign LibOVR;

ovrSessionStatus :: struct {
    IsVisible: ovrBool;
    HmdPresent: ovrBool;
    HmdMounted: ovrBool;
    DisplayLost: ovrBool;
    ShouldQuit: ovrBool;
    ShouldRecenter: ovrBool;
    HasInputFocus: ovrBool;
    OverlayPresent: ovrBool;
    DepthRequested: ovrBool;
};

ovr_GetSessionStatus :: (session: ovrSession, sessionStatus: *ovrSessionStatus) -> ovrResult #foreign LibOVR;
ovr_IsExtensionSupported :: (session: ovrSession, extension: ovrExtensions, outExtensionSupported: *ovrBool) -> ovrResult #foreign LibOVR;
ovr_EnableExtension :: (session: ovrSession, extension: ovrExtensions) -> ovrResult #foreign LibOVR;
ovr_SetTrackingOriginType :: (session: ovrSession, origin: ovrTrackingOrigin) -> ovrResult #foreign LibOVR;
ovr_GetTrackingOriginType :: (session: ovrSession) -> ovrTrackingOrigin #foreign LibOVR;
ovr_RecenterTrackingOrigin :: (session: ovrSession) -> ovrResult #foreign LibOVR;
ovr_SpecifyTrackingOrigin :: (session: ovrSession, originPose: ovrPosef) -> ovrResult #foreign LibOVR;
ovr_ClearShouldRecenterFlag :: (session: ovrSession) #foreign LibOVR;
ovr_GetTrackingState :: (session: ovrSession, absTime: float64, latencyMarker: ovrBool) -> ovrTrackingState #foreign LibOVR;
ovr_GetDevicePoses :: (session: ovrSession, deviceTypes: *ovrTrackedDeviceType, deviceCount: s32, absTime: float64, outDevicePoses: *ovrPoseStatef) -> ovrResult #foreign LibOVR;
ovr_GetTrackerPose :: (session: ovrSession, trackerPoseIndex: u32) -> ovrTrackerPose #foreign LibOVR;
ovr_GetInputState :: (session: ovrSession, controllerType: ovrControllerType, inputState: *ovrInputState) -> ovrResult #foreign LibOVR;
ovr_GetConnectedControllerTypes :: (session: ovrSession) -> u32 #foreign LibOVR;
ovr_GetTouchHapticsDesc :: (session: ovrSession, controllerType: ovrControllerType) -> ovrTouchHapticsDesc #foreign LibOVR;
ovr_SetControllerVibration :: (session: ovrSession, controllerType: ovrControllerType, frequency: float, amplitude: float) -> ovrResult #foreign LibOVR;
ovr_SubmitControllerVibration :: (session: ovrSession, controllerType: ovrControllerType, buffer: *ovrHapticsBuffer) -> ovrResult #foreign LibOVR;
ovr_GetControllerVibrationState :: (session: ovrSession, controllerType: ovrControllerType, outState: *ovrHapticsPlaybackState) -> ovrResult #foreign LibOVR;
ovr_TestBoundary :: (session: ovrSession, deviceBitmask: ovrTrackedDeviceType, boundaryType: ovrBoundaryType, outTestResult: *ovrBoundaryTestResult) -> ovrResult #foreign LibOVR;
ovr_TestBoundaryPoint :: (session: ovrSession, point: *ovrVector3f, singleBoundaryType: ovrBoundaryType, outTestResult: *ovrBoundaryTestResult) -> ovrResult #foreign LibOVR;
ovr_SetBoundaryLookAndFeel :: (session: ovrSession, lookAndFeel: *ovrBoundaryLookAndFeel) -> ovrResult #foreign LibOVR;
ovr_ResetBoundaryLookAndFeel :: (session: ovrSession) -> ovrResult #foreign LibOVR;
ovr_GetBoundaryGeometry :: (session: ovrSession, boundaryType: ovrBoundaryType, outFloorPoints: *ovrVector3f, outFloorPointsCount: *s32) -> ovrResult #foreign LibOVR;
ovr_GetBoundaryDimensions :: (session: ovrSession, boundaryType: ovrBoundaryType, outDimensions: *ovrVector3f) -> ovrResult #foreign LibOVR;
ovr_GetBoundaryVisible :: (session: ovrSession, outIsVisible: *ovrBool) -> ovrResult #foreign LibOVR;
ovr_RequestBoundaryVisible :: (session: ovrSession, visible: ovrBool) -> ovrResult #foreign LibOVR;
ovr_GetExternalCameras :: (session: ovrSession, cameras: *ovrExternalCamera, inoutCameraCount: *u32) -> ovrResult #foreign LibOVR;
ovr_SetExternalCameraProperties :: (session: ovrSession, name: *u8, intrinsics: *ovrCameraIntrinsics, extrinsics: *ovrCameraExtrinsics) -> ovrResult #foreign LibOVR;

enum { ovrMaxLayerCount :: 16; };

using ovrLayerType :: enum s32 {
    ovrLayerType_Disabled :: 0;
    ovrLayerType_EyeFov :: 1;
    ovrLayerType_EyeFovDepth :: 2;
    ovrLayerType_Quad :: 3;
    ovrLayerType_EyeMatrix :: 5;
    ovrLayerType_EyeFovMultires :: 7;
    ovrLayerType_Cylinder :: 8;
    ovrLayerType_Cube :: 10;
    ovrLayerType_EnumSize :: 0x7fffffff;
};

using ovrLayerFlags :: enum {
    ovrLayerFlag_HighQuality :: 0x01;
    ovrLayerFlag_TextureOriginAtBottomLeft :: 0x02;
    ovrLayerFlag_HeadLocked :: 0x04;
};

// @Align(size_of(*void))
ovrLayerHeader :: struct {
    alignment: *void; #place alignment;

    Type: ovrLayerType;
    Flags: u32;
    Reserved: [128] u8;
};

// @Align(size_of(*void))
ovrLayerEyeFov :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    ColorTexture: [ovrEye_Count] ovrTextureSwapChain;
    Viewport: [ovrEye_Count] ovrRecti;
    Fov: [ovrEye_Count] ovrFovPort;
    RenderPose: [ovrEye_Count] ovrPosef;
    SensorSampleTime: float64;
};

// @Align(size_of(*void))
ovrLayerEyeFovDepth :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    ColorTexture: [ovrEye_Count] ovrTextureSwapChain;
    Viewport: [ovrEye_Count] ovrRecti;
    Fov: [ovrEye_Count] ovrFovPort;
    RenderPose: [ovrEye_Count] ovrPosef;
    SensorSampleTime: float64;
    DepthTexture: [ovrEye_Count] ovrTextureSwapChain;
    ProjectionDesc: ovrTimewarpProjectionDesc;
};

ovrTextureLayout :: enum s32 {
    ovrTextureLayout_Rectilinear :: 0;
    ovrTextureLayout_Octilinear :: 1;
    ovrTextureLayout_EnumSize :: 0x7fffffff;
};

// @Align(size_of(*void))
ovrTextureLayoutOctilinear :: struct {
    alignment: *void; #place alignment;

    WarpLeft: float;
    WarpRight: float;
    WarpUp: float;
    WarpDown: float;

    SizeLeft: float;
    SizeRight: float;
    SizeUp: float;
    SizeDown: float;
};

// @Align(size_of(*void))
ovrTextureLayoutDesc_Union :: union {
    // alignment: *void; #place alignment;

    Octilinear: [ovrEye_Count] ovrTextureLayoutOctilinear;
};

// @Align(size_of(*void))
ovrLayerEyeFovMultires :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    ColorTexture: [ovrEye_Count] ovrTextureSwapChain;
    Viewport: [ovrEye_Count] ovrRecti;
    Fov: [ovrEye_Count] ovrFovPort;
    RenderPose: [ovrEye_Count] ovrPosef;
    SensorSampleTime: float64;
    TextureLayout: ovrTextureLayout;
    TextureLayoutDesc: ovrTextureLayoutDesc_Union;
};

// @Align(size_of(*void))
ovrLayerEyeMatrix :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    ColorTexture: [ovrEye_Count] ovrTextureSwapChain ;
    Viewport: [ovrEye_Count] ovrRecti ;
    RenderPose: [ovrEye_Count] ovrPosef ;
    Matrix: [ovrEye_Count] ovrMatrix4f ;
    SensorSampleTime: float64;
};

// @Align(size_of(*void))
ovrLayerQuad :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    ColorTexture: ovrTextureSwapChain;
    Viewport: ovrRecti;
    QuadPoseCenter: ovrPosef;
    QuadSize: ovrVector2f;
};

// @Align(size_of(*void))
ovrLayerCylinder :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    ColorTexture: ovrTextureSwapChain;
    Viewport: ovrRecti;
    CylinderRadius: float;
    CylinderAngle: float;
    CylinderAspectRatio: float;
};

// @Align(size_of(*void))
ovrLayerCube :: struct {
    alignment: *void; #place alignment;

    Header: ovrLayerHeader;
    Orientation: ovrQuatf;
    CubeMapTexture: ovrTextureSwapChain;
};

ovrLayer_Union :: union {
    Header: ovrLayerHeader;
    EyeFov: ovrLayerEyeFov;
    EyeFovDepth: ovrLayerEyeFovDepth;
    Quad: ovrLayerQuad;
    EyeMatrix: ovrLayerEyeMatrix;
    Multires: ovrLayerEyeFovMultires;
    Cylinder: ovrLayerCylinder;
    Cube: ovrLayerCube;
};

ovr_GetTextureSwapChainLength :: (session: ovrSession, chain: ovrTextureSwapChain, out_Length: s32) -> ovrResult #foreign LibOVR;
ovr_GetTextureSwapChainCurrentIndex :: (session: ovrSession, chain: ovrTextureSwapChain, out_Index: *s32) -> ovrResult #foreign LibOVR;
ovr_GetTextureSwapChainDesc :: (session: ovrSession, chain: ovrTextureSwapChain, out_Desc: *ovrTextureSwapChainDesc) -> ovrResult #foreign LibOVR;
ovr_CommitTextureSwapChain :: (session: ovrSession, chain: ovrTextureSwapChain) -> ovrResult #foreign LibOVR;
ovr_DestroyTextureSwapChain :: (session: ovrSession, chain: ovrTextureSwapChain) #foreign LibOVR;
ovr_DestroyMirrorTexture :: (session: ovrSession, mirrorTexture: ovrMirrorTexture) #foreign LibOVR;
ovr_GetFovTextureSize :: (session: ovrSession, eye: ovrEyeType, fov: ovrFovPort, pixelsPerDisplayPixel: float) -> ovrSizei #foreign LibOVR;
ovr_GetRenderDesc :: (session: ovrSession, eyeType: ovrEyeType, fov: ovrFovPort) -> ovrEyeRenderDesc #foreign LibOVR;
ovr_WaitToBeginFrame :: (session: ovrSession, frameIndex: s64) -> ovrResult #foreign LibOVR;
ovr_BeginFrame :: (session: ovrSession, frameIndex: s64) -> ovrResult #foreign LibOVR;
ovr_EndFrame :: (session: ovrSession, frameIndex: s64, viewScaleDesc: *ovrViewScaleDesc, layerPtrList: **ovrLayerHeader, layerCount: u32) -> ovrResult #foreign LibOVR;
ovr_SubmitFrame :: (session: ovrSession, frameIndex: s64, viewScaleDesc: *ovrViewScaleDesc, layerPtrList: **ovrLayerHeader, layerCount: u32) -> ovrResult #foreign LibOVR;

// @Align(4)
ovrPerfStatsPerCompositorFrame :: struct {
    HmdVsyncIndex: s32;
    AppFrameIndex: s32;
    AppDroppedFrameCount: s32;
    AppMotionToPhotonLatency: float;
    AppQueueAheadTime: float;
    AppCpuElapsedTime: float;
    AppGpuElapsedTime: float;
    CompositorFrameIndex: s32;
    CompositorDroppedFrameCount: s32;
    CompositorLatency: float;
    CompositorCpuElapsedTime: float;
    CompositorGpuElapsedTime: float;
    CompositorCpuStartToGpuEndElapsedTime: float;
    CompositorGpuEndToVsyncElapsedTime: float;
    AswIsActive: ovrBool;
    AswActivatedToggleCount: s32;
    AswPresentedFrameCount: s32;
    AswFailedFrameCount: s32;
};

enum { ovrMaxProvidedFrameStats :: 5; };

// @Align(4)
ovrPerfStats :: struct {
    FrameStats: [ovrMaxProvidedFrameStats] ovrPerfStatsPerCompositorFrame;
    FrameStatsCount: s32;
    AnyFrameStatsDropped: ovrBool;
    AdaptiveGpuPerformanceScale: float;
    AswIsAvailable: ovrBool;
    VisibleProcessId: ovrProcessId;
};

ovr_GetPerfStats :: (session: ovrSession, outStats: *ovrPerfStats) -> ovrResult #foreign LibOVR;
ovr_ResetPerfStats :: (session: ovrSession) -> ovrResult #foreign LibOVR;
ovr_GetPredictedDisplayTime :: (session: ovrSession, frameIndex: s64) -> float64 #foreign LibOVR;
ovr_GetTimeInSeconds :: () -> float64 #foreign LibOVR;

using ovrPerfHudMode :: enum s32 {
    ovrPerfHud_Off :: 0;
    ovrPerfHud_PerfSummary :: 1;
    ovrPerfHud_LatencyTiming :: 2;
    ovrPerfHud_AppRenderTiming :: 3;
    ovrPerfHud_CompRenderTiming :: 4;
    ovrPerfHud_AswStats :: 6;
    ovrPerfHud_VersionInfo :: 5;
    ovrPerfHud_Count :: 7;
    ovrPerfHud_EnumSize :: 0x7fffffff;
};

using ovrLayerHudMode :: enum s32 {
    ovrLayerHud_Off :: 0;
    ovrLayerHud_Info :: 1;
    ovrLayerHud_EnumSize :: 0x7fffffff;
};

using ovrDebugHudStereoMode :: enum s32 {
    ovrDebugHudStereo_Off :: 0;
    ovrDebugHudStereo_Quad :: 1;
    ovrDebugHudStereo_QuadWithCrosshair :: 2;
    ovrDebugHudStereo_CrosshairAtInfinity :: 3;
    ovrDebugHudStereo_Count;
    ovrDebugHudStereo_EnumSize :: 0x7fffffff;
};

ovr_GetBool :: (session: ovrSession, propertyName: *u8, defaultVal: ovrBool) -> ovrBool #foreign LibOVR;
ovr_SetBool :: (session: ovrSession, propertyName: *u8, value: ovrBool) -> ovrBool #foreign LibOVR;
ovr_GetInt :: (session: ovrSession, propertyName: *u8, defaultVal: s32) -> s32 #foreign LibOVR;
ovr_SetInt :: (session: ovrSession, propertyName: *u8, value: s32) -> ovrBool #foreign LibOVR;
ovr_GetFloat :: (session: ovrSession, propertyName: *u8, defaultVal: float) -> float #foreign LibOVR;
ovr_SetFloat :: (session: ovrSession, propertyName: *u8, value: float) -> ovrBool #foreign LibOVR;
ovr_GetFloatArray :: (session: ovrSession, propertyName: *u8, values: /*float []*/ *float, valuesCapacity: u32) -> u32 #foreign LibOVR;
ovr_SetFloatArray :: (session: ovrSession, propertyName: *u8, values: /*float []*/ *float, valuesSize: u32) -> ovrBool #foreign LibOVR;
ovr_GetString :: (session: ovrSession, propertyName: *u8, defaultVal: *u8) -> *u8 #foreign LibOVR;
ovr_SetString :: (session: ovrSession, propertyName: *u8, value: *u8) -> ovrBool #foreign LibOVR;

#assert (size_of(ovrTextureSwapChainDesc) == 10 * 4) "ovrTextureSwapChainDesc size mismatch";

// C API Errors

ovrResult :: s32;

OVR_SUCCESS :: (result: $T) -> bool { return result >= 0; }

OVR_UNQUALIFIED_SUCCESS :: (result: $T) -> bool { return result == (xx ovrSuccess); }

OVR_FAILURE :: (result: $T) -> bool { return !OVR_SUCCESS(result); }

using ovrSuccessType :: enum {
    ovrSuccess :: 0;
};

ovrSuccessTypes :: enum {
    ovrSuccess_NotVisible :: 1000;
    ovrSuccess_BoundaryInvalid :: 1001;
    ovrSuccess_DeviceUnavailable :: 1002;
};

ovrErrorType :: enum {
    ovrError_MmoryAllocationFailure :: -1000;
    ovrError_InvalidSession :: -1002;
    ovrError_Timeout :: -1003;
    ovrError_NotInitialized :: -1004;
    ovrError_InvalidParameter :: -1005;
    ovrError_ServiceError :: -1006;
    ovrError_NoHmd :: -1007;
    ovrError_Unsupported :: -1009;
    ovrError_DeviceUnavailable :: -1010;
    ovrError_InvalidHeadsetOrientation :: -1011;
    ovrError_ClientSkippedDestroy :: -1012;
    ovrError_ClientSkippedShutdown :: -1013;
    ovrError_ServiceDeadlockDetected :: -1014;
    ovrError_InvalidOperation :: -1015;
    ovrError_InsufficientArraySize :: -1016;
    ovrError_NoExternalCameraInfo :: -1017;
    ovrError_LostTracking :: -1018;
    ovrError_ExternalCameraInitializedFailed :: -1019;
    ovrError_ExternalCameraCaptureFailed :: -1020;
    ovrError_ExternalCameraNameListsBufferSize :: -1021;
    ovrError_ExternalCameraNameListsMistmatch :: -1022;
    ovrError_ExternalCameraNotCalibrated :: -1023;
    ovrError_ExternalCameraNameWrongSize :: -1024;
    ovrError_AudioDeviceNotFound :: -2001;
    ovrError_AudioComError :: -2002;
    ovrError_Initialize :: -3000;
    ovrError_LibLoad :: -3001;
    ovrError_LibVersion :: -3002;
    ovrError_ServiceConnection :: -3003;
    ovrError_ServiceVersion :: -3004;
    ovrError_IncompatibleOS :: -3005;
    ovrError_DisplayInit :: -3006;
    ovrError_ServerStart :: -3007;
    ovrError_Reinitialization :: -3008;
    ovrError_MismatchedAdapters :: -3009;
    ovrError_LeakingResources :: -3010;
    ovrError_ClientVersion :: -3011;
    ovrError_OutOfDateOS :: -3012;
    ovrError_OutOfDateGfxDriver :: -3013;
    ovrError_IncompatibleGPU :: -3014;
    ovrError_NoValidVRDisplaySystem :: -3015;
    ovrError_Obsolete :: -3016;
    ovrError_DisabledOrDefaultAdapter :: -3017;
    ovrError_HybridGraphicsNotSupported :: -3018;
    ovrError_DisplayManagerInit :: -3019;
    ovrError_TrackerDriverInit :: -3020;
    ovrError_LibSignCheck :: -3021;
    ovrError_LibPath :: -3022;
    ovrError_LibSymbols :: -3023;
    ovrError_RemoteSession :: -3024;
    ovrError_InitializeVulkan :: -3025;
    ovrError_BlacklistedGfxDriver :: -3026;
    ovrError_DisplayLost :: -6000;
    ovrError_TextureSwapChainFull :: -6001;
    ovrError_TextureSwapChainInvalid :: -6002;
    ovrError_GraphicsDeviceReset :: -6003;
    ovrError_DisplayRemoved :: -6004;
    ovrError_ContentProtectionNotAvailable :: -6005;
    ovrError_ApplicationInvisible :: -6006;
    ovrError_Disallowed :: -6007;
    ovrError_DisplayPluggedIncorrectly :: -6008;
    ovrError_DisplayLimitReached :: -6009;
    ovrError_RuntimeException :: -7000;
    ovrError_NoCalibration :: -9000;
    ovrError_OldVersion :: -9001;
    ovrError_MisformattedBlock :: -9002;
};

ovrErrorInfo :: struct {
    Result: ovrResult;
    ErrorString: [512] u8;
};

// C API Error


// C API OpenGL

ovr_CreateTextureSwapChainGL :: (session: ovrSession, desc: *ovrTextureSwapChainDesc, out_TextureSwapChain: *ovrTextureSwapChain) -> ovrResult #foreign LibOVR;
ovr_GetTextureSwapChainBufferGL :: (session: ovrSession, chain: ovrTextureSwapChain, index: s32, out_TexId: *u32) -> ovrResult #foreign LibOVR;
ovr_CreateMirrorTextureWithOptionsGL :: (session: ovrSession, desc: *ovrMirrorTextureDesc, out_MirrorTexture: *ovrMirrorTexture) -> ovrResult #foreign LibOVR;
ovr_CreateMirrorTextureGL :: (session: ovrSession, desc: *ovrMirrorTextureDesc, out_MirrorTexture: *ovrMirrorTexture) -> ovrResult #foreign LibOVR;
ovr_GetMirrorTextureBufferGL :: (session: ovrSession, mirrorTexture: ovrMirrorTexture, out_TexId: *u32) -> ovrResult #foreign LibOVR;

// C API OpenGL

// C API Util


using ovrProjectionModifier :: enum {
    ovrProjection_None :: 0x00;
    ovrProjection_LeftHanded :: 0x01;
    ovrProjection_FarLessThanNear :: 0x02;
    ovrProjection_FarClipAtInfinity :: 0x04;
    ovrProjection_ClipRangeOpenGL :: 0x08;
};

// @Align(8)
ovrDetectResult :: struct {
    alignment: s64; #place alignment;

    IsOculusServiceRunning: ovrBool;
    IsOculusHMDConnected: ovrBool;
    pad0: [6] u8;
};

#assert (size_of(ovrDetectResult) == 8) "ovrDetectResult size mismatch";

using ovrHapticsGenMode :: enum {
    ovrHapticsGenMode_PointSample;
    ovrHapticsGenMode_Count;
};


ovrAudioChannelData :: struct {
    Samples: *float;
    SamplesCount: s32;
    Frequency: s32;
};


ovrHapticsClip :: struct {
    Samples: *void;
    SamplesCount: s32;
};

ovr_Detect :: (timeoutMilliseconds: s32) -> ovrDetectResult #foreign LibOVR;

#if OS_WINDOWS {
    OVR_HMD_CONNECTED_EVENT_NAME :: "OculusHMDConnected";
}

ovrMatrix4f_Projection :: (fov: ovrFovPort, znear: float, zfar: float, projectionModFlags: u32) -> ovrMatrix4f #foreign LibOVR;

ovrTimewarpProjectionDesc_FromProjection :: (projection: ovrMatrix4f, projectionModFlags: u32) -> ovrTimewarpProjectionDesc #foreign LibOVR;

ovrMatrix4f_OrthoSubProjection :: (projection: ovrMatrix4f, orthoScale: ovrVector2f, orthoDistance: float, HmdToEyeOffsetX: float) -> ovrMatrix4f #foreign LibOVR;

_ovr_CalcEyePoses :: (headPose: ovrPosef, hmdToEyeOffset: [2] ovrVector3f, outEyePoses: [2] ovrPosef) #foreign LibOVR "ovr_CalcEyePoses";

ovr_CalcEyePoses2 :: (headPose: ovrPosef, HmdToEyePose: *ovrPosef, outEyePoses: *ovrPosef) #foreign LibOVR;
// for some reason there's an ovr_CalcEyePoses but it's then #define'd to ovr_CalcEyePoses2
ovr_CalcEyePoses :: ovr_CalcEyePoses2;

_ovr_GetEyePoses :: (session: ovrSession, frameIndex: s64, latencyMarker: ovrBool, hmdToEyeOffset: [2] ovrVector3f, outEyePoses: [2] ovrPosef, outSensorSampleTime: *float64) #foreign LibOVR "ovr_GetEyePoses";

ovr_GetEyePoses2 :: (session: ovrSession, frameIndex: s64, latencyMarker: ovrBool, HmdToEyePose: [2] ovrPosef, outEyePoses: [2] ovrPosef, outSensorSampleTime: *float64) #foreign LibOVR;

ovr_GetEyePoses :: ovr_GetEyePoses2;

ovrPosef_FlipHandedness :: (inPose: *ovrPosef, outPose: *ovrPosef) #foreign LibOVR;

ovr_ReadWavFromBuffer :: (outAudioChannel: *ovrAudioChannelData, inputData: *void, dataSizeInBytes: s32, stereoChannelToUse: s32) -> ovrResult #foreign LibOVR;

ovr_GenHapticsFromAudioData :: (outHapticsClip: *ovrHapticsClip, audioChannel: *ovrAudioChannelData, genMode: ovrHapticsGenMode) -> ovrResult #foreign LibOVR;;

ovr_ReleaseAudioChannelData :: (audioChannel: *ovrAudioChannelData) #foreign LibOVR;

ovr_ReleaseHapticsClip :: (hapticsClip: *ovrHapticsClip) #foreign LibOVR;

// C API Util

// OVR Version

OVR_PRODUCT_VERSION :: 1;
OVR_MAJOR_VERSION :: 1;
OVR_MINOR_VERSION :: 26;
OVR_PATCH_VERSION :: 0;
OVR_BUILD_NUMBER :: 0;

OVR_DLL_COMPATIBLE_VERSION :: 101;

OVR_MIN_REQUESTABLE_MINOR_VERSION :: 17;

OVR_FEATURE_VERSION :: 0;

OVR_VERSION_STRING :: #run sprint("%.%.%", OVR_MAJOR_VERSION, OVR_MINOR_VERSION, OVR_PATCH_VERSION);
OVR_DETAILED_VERSION_STRING :: #run sprint("%.%.%.%", OVR_MAJOR_VERSION, OVR_MINOR_VERSION, OVR_PATCH_VERSION, OVR_BUILD_NUMBER);

// OVR Version
