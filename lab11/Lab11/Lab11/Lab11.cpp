// Lab11.cpp: ���������� ����� ����� ��� ����������.
//

#include "stdafx.h"
#include "Lab11.h"
#include "vectsse.h"
#include "vectfpu.h"
#include "module.h"

#define MAX_LOADSTRING 100

// ���������� ����������:
HINSTANCE hInst;                                // ������� ���������
WCHAR szTitle[MAX_LOADSTRING];                  // ����� ������ ���������
WCHAR szWindowClass[MAX_LOADSTRING];            // ��� ������ �������� ����

// ��������� ���������� �������, ���������� � ���� ������ ����:
ATOM                MyRegisterClass(HINSTANCE hInstance);
BOOL                InitInstance(HINSTANCE, int);
LRESULT CALLBACK    WndProc(HWND, UINT, WPARAM, LPARAM);
INT_PTR CALLBACK    About(HWND, UINT, WPARAM, LPARAM);
VOID GetTime(HWND hWnd);


int APIENTRY wWinMain(_In_ HINSTANCE hInstance,
                     _In_opt_ HINSTANCE hPrevInstance,
                     _In_ LPWSTR    lpCmdLine,
                     _In_ int       nCmdShow)
{
    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpCmdLine);

    // TODO: ���������� ��� �����.

    // ������������� ���������� �����
    LoadStringW(hInstance, IDS_APP_TITLE, szTitle, MAX_LOADSTRING);
    LoadStringW(hInstance, IDC_LAB11, szWindowClass, MAX_LOADSTRING);
    MyRegisterClass(hInstance);

    // ��������� ������������� ����������:
    if (!InitInstance (hInstance, nCmdShow))
    {
        return FALSE;
    }

    HACCEL hAccelTable = LoadAccelerators(hInstance, MAKEINTRESOURCE(IDC_LAB11));

    MSG msg;

    // ���� ��������� ���������:
    while (GetMessage(&msg, nullptr, 0, 0))
    {
        if (!TranslateAccelerator(msg.hwnd, hAccelTable, &msg))
        {
            TranslateMessage(&msg);
            DispatchMessage(&msg);
        }
    }

    return (int) msg.wParam;
}



//
//  �������: MyRegisterClass()
//
//  ����������: ������������ ����� ����.
//
ATOM MyRegisterClass(HINSTANCE hInstance)
{
    WNDCLASSEXW wcex;

    wcex.cbSize = sizeof(WNDCLASSEX);

    wcex.style          = CS_HREDRAW | CS_VREDRAW;
    wcex.lpfnWndProc    = WndProc;
    wcex.cbClsExtra     = 0;
    wcex.cbWndExtra     = 0;
    wcex.hInstance      = hInstance;
    wcex.hIcon          = LoadIcon(hInstance, MAKEINTRESOURCE(IDI_LAB11));
    wcex.hCursor        = LoadCursor(nullptr, IDC_ARROW);
    wcex.hbrBackground  = (HBRUSH)(COLOR_WINDOW+1);
    wcex.lpszMenuName   = MAKEINTRESOURCEW(IDC_LAB11);
    wcex.lpszClassName  = szWindowClass;
    wcex.hIconSm        = LoadIcon(wcex.hInstance, MAKEINTRESOURCE(IDI_SMALL));

    return RegisterClassExW(&wcex);
}

//
//   �������: InitInstance(HINSTANCE, int)
//
//   ����������: ��������� ��������� ���������� � ������� ������� ����.
//
//   �����������:
//
//        � ������ ������� ���������� ���������� ����������� � ���������� ����������, � �����
//        ��������� � ��������� �� ����� ������� ���� ���������.
//
BOOL InitInstance(HINSTANCE hInstance, int nCmdShow)
{
   hInst = hInstance; // ��������� ���������� ���������� � ���������� ����������

   HWND hWnd = CreateWindowW(szWindowClass, L"szTitle", WS_OVERLAPPEDWINDOW,
      CW_USEDEFAULT, 0, CW_USEDEFAULT, 0, nullptr, nullptr, hInstance, nullptr);

   if (!hWnd)
   {
      return FALSE;
   }

   ShowWindow(hWnd, nCmdShow);
   UpdateWindow(hWnd);

   return TRUE;
}

//
//  �������: WndProc(HWND, UINT, WPARAM, LPARAM)
//
//  ����������:  ������������ ��������� � ������� ����.
//
//  WM_COMMAND � ���������� ���� ����������
//  WM_PAINT � ���������� ������� ����
//  WM_DESTROY � ��������� ��������� � ������ � ���������
//
//
LRESULT CALLBACK WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam)
{
    switch (message)
    {
    case WM_COMMAND:
        {
            int wmId = LOWORD(wParam);
            // ��������� ����� � ����:
            switch (wmId)
            {
            case IDM_ABOUT:
                DialogBox(hInst, MAKEINTRESOURCE(IDD_ABOUTBOX), hWnd, About);
                break;
            case IDM_EXIT:
                DestroyWindow(hWnd);
                break;
			case ID_32771:
				GetTime(hWnd);
				break;
            default:
                return DefWindowProc(hWnd, message, wParam, lParam);
            }
        }
        break;
    case WM_PAINT:
        {
            PAINTSTRUCT ps;
            HDC hdc = BeginPaint(hWnd, &ps);
            // TODO: �������� ���� ����� ��� ����������, ������������ HDC...
            EndPaint(hWnd, &ps);
        }
        break;
    case WM_DESTROY:
        PostQuitMessage(0);
        break;
    default:
        return DefWindowProc(hWnd, message, wParam, lParam);
    }
    return 0;
}

// ���������� ��������� ��� ���� "� ���������".
INT_PTR CALLBACK About(HWND hDlg, UINT message, WPARAM wParam, LPARAM lParam)
{
    UNREFERENCED_PARAMETER(lParam);
    switch (message)
    {
    case WM_INITDIALOG:
        return (INT_PTR)TRUE;

    case WM_COMMAND:
        if (LOWORD(wParam) == IDOK || LOWORD(wParam) == IDCANCEL)
        {
            EndDialog(hDlg, LOWORD(wParam));
            return (INT_PTR)TRUE;
        }
        break;
    }
    return (INT_PTR)FALSE;
}



void DotProduct(float* result, float* vectorA, float* vectorB, int n) {
	*result = 0.0;

	for (int i = 0; i < n; i++) {
		*result += vectorA[i] * vectorB[i];
	}
};


void strTime(char* str) {
	memset(str, ' ', 50);
	str[20] = 13;
	str[21] = 10;
	str[22] = 'T';
	str[23] = 'i';
	str[24] = 'm';
	str[25] = 'e';
	str[26] = ':';
	str[27] = ' ';
	str[49] = '\0';
}

void GetTime(HWND hWnd) {

	char str[50];

	const unsigned int n = 40 * 16;
	_declspec(align(16)) float VectorA[n];
	_declspec(align(16)) float VectorB[n];
	float result;

	memset(VectorA, 0, sizeof(VectorA));
	memset(VectorB, 0, sizeof(VectorB));
	result = 0;

	VectorA[0] = 3;
	VectorA[1] = 2;
	VectorB[0] = 5;
	VectorB[1] = 4;


	SYSTEMTIME st;
	long tst, ten;

	// SSE
	GetLocalTime(&st);
	tst = 60000 * (long)st.wMinute + 1000 * (long)st.wSecond + (long)st.wMilliseconds;
	for (long i = 0; i < 1000000; i++) {
		DotProductSSE(&result, VectorA, VectorB, n);
	}
	GetLocalTime(&st);
	ten = 60000 * (long)st.wMinute + 1000 * (long)st.wSecond + (long)st.wMilliseconds - tst;
	strTime(str);
	StrDec(32, &ten, &str[28]);	
	FloatToDec32(str, &result);
	MessageBox(0, str, "Result SEE", MB_OK);

	// FPU
	GetLocalTime(&st);
	tst = 60000 * (long)st.wMinute + 1000 * (long)st.wSecond + (long)st.wMilliseconds;
	for (long i = 0; i < 1000000; i++) {
		DotProductFPU(&result, VectorA, VectorB, n);
	}
	GetLocalTime(&st);
	ten = 60000 * (long)st.wMinute + 1000 * (long)st.wSecond + (long)st.wMilliseconds - tst;
	strTime(str);
	StrDec(32, &ten, &str[28]);
	FloatToDec32(str, &result);
	MessageBox(0, str, "Result FPU", MB_OK);

	// C++
	GetLocalTime(&st);
	tst = 60000 * (long)st.wMinute + 1000 * (long)st.wSecond + (long)st.wMilliseconds;
	for (long i = 0; i < 1000000; i++) {
		DotProduct(&result, VectorA, VectorB, n);
	}
	GetLocalTime(&st);
	ten = 60000 * (long)st.wMinute + 1000 * (long)st.wSecond + (long)st.wMilliseconds - tst;
	strTime(str);
	StrDec(32, &ten, &str[28]);
	FloatToDec32(str, &result);
	MessageBox(0, str, "Result C++", MB_OK);
}
