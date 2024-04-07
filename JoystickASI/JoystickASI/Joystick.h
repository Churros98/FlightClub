#pragma once
#include <dinput.h>

#define MAX_DIRECTION_VALUE 65534

typedef struct {
	long pitch;
	long yaw;
	long roll;
	long power;
	DWORD pov;
	bool fireButton;
	bool gearButton;
	bool reverseButton;
	bool airbreakButton;
} JoystickData;

class Joystick {
public:
	Joystick();
	~Joystick();
	BOOL ConnectJoystick();
	void UnconnectJoystick();
	BOOL IsJoystickInitialized();
	BOOL IsJoystickConnected();
	HRESULT GetInput(JoystickData* inputData);

private:
	IDirectInput8* directInput;
	IDirectInputDevice8* joystick;

	HRESULT InitializeJoystick();
	HRESULT InitializeDirectInput();
	void UninitializeDirectInput();
};