#pragma once

class Script {
	public:
		static void Initialize();
		static void DebugText(float x, float y, const char* str, ...);
		static void Run();
};
