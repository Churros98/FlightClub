#include "dinput.h"
#include "dinputd.h"

#include "Joystick.h"

// Initialisation de la classe
Joystick::Joystick()
{
    if (FAILED(InitializeDirectInput())) {
        directInput = NULL;
        return;
    }

    InitializeJoystick();
}

// Dé-initialisation de la classe Joystick
Joystick::~Joystick()
{
    if (joystick) {
        UnconnectJoystick();
    }

    if (directInput) {
        UninitializeDirectInput();
    }
}

// Fonction qui permet de re-tenter de connecter un Joystick
BOOL Joystick::ConnectJoystick()
{
    if (FAILED(InitializeJoystick()))
        return false;

    return true;
}

// Fonction qui permet la déconnexion du Joystick
void Joystick::UnconnectJoystick()
{
    joystick->Unacquire();
    joystick->Release();
    joystick = NULL;
}

// Retourne true si la classe est correctement initialiser
BOOL Joystick::IsJoystickInitialized()
{
    if (directInput != NULL)
        return true;

    return false;
}

// Retourne true is un Joystick est actuellement connecté
BOOL Joystick::IsJoystickConnected()
{
    if (joystick != NULL)
        return true;

    return false;
}

// Retourne une structure de données contenant les inputs du Joystick
HRESULT Joystick::GetInput(JoystickData* inputData) {
    DIJOYSTATE joystickState;
    HRESULT result = joystick->GetDeviceState(sizeof(DIJOYSTATE), &joystickState);
    if (FAILED(result))
    {
        return result;
    }

    memset(inputData, 0, sizeof(JoystickData));
    inputData->roll = joystickState.lX;
    inputData->pitch = joystickState.lY;
    inputData->yaw = joystickState.lRz;
    inputData->power = MAX_DIRECTION_VALUE - joystickState.rglSlider[0];
    inputData->pov = joystickState.rgdwPOV[0];
    inputData->fireButton = joystickState.rgbButtons[0] ? true : false;
    inputData->gearButton = joystickState.rgbButtons[2] ? true : false;
    memcpy(inputData->allButtons, joystickState.rgbButtons, 32 * sizeof(BYTE));



    return S_OK;
}

// Tente de se connecter au 1er Joystick connectée
HRESULT Joystick::InitializeJoystick()
{
    HRESULT result = directInput->CreateDevice(GUID_Joystick, &joystick, NULL);
    if (FAILED(result))
    {
        return result;
    }

    result = joystick->SetDataFormat(&c_dfDIJoystick);
    if (FAILED(result))
    {
        joystick->Release();
        joystick = NULL;
        return result;
    }

    result = joystick->SetCooperativeLevel(NULL, DISCL_BACKGROUND | DISCL_NONEXCLUSIVE);
    if (FAILED(result))
    {
        joystick->Release();
        joystick = NULL;
        return result;
    }

    result = joystick->Acquire();
    if (FAILED(result))
    {
        joystick->Release();
        joystick = NULL;
        return result;
    }
}

// Initialize DirectInput
HRESULT Joystick::InitializeDirectInput()
{
    return DirectInput8Create(GetModuleHandle(NULL), DIRECTINPUT_VERSION, IID_IDirectInput8, (void**)&directInput, NULL);
}

// Uninitialize DirectInput
void Joystick::UninitializeDirectInput()
{
    directInput->Release();
    directInput = NULL;
}