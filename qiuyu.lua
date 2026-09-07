require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.Color"
import "android.graphics.Typeface"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.ColorDrawable"
import "android.graphics.LinearGradient"
import "android.graphics.Shader"
import "android.view.ViewTreeObserver"
import "android.os.Build"
import "android.content.Intent"
import "android.net.Uri"
import "android.provider.Settings"
import "java.io.File"
import "java.lang.System"

activity.setTheme(android.R.style.Theme_Black_NoTitleBar)
if activity.getActionBar() then activity.getActionBar().hide() end
local window = activity.getWindow()
if Build.VERSION.SDK_INT >= 21 then
  window.setStatusBarColor(Color.TRANSPARENT)
  window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_STABLE)
end
window.getDecorView().setBackgroundColor(Color.BLACK)

local density = activity.getResources().getDisplayMetrics().density

local function showCustomDialog(title, msg, btnText, callback)
  local dialog = Dialog(activity)
  dialog.setCancelable(false)
  local dLayout = LinearLayout(activity)
  dLayout.setOrientation(LinearLayout.VERTICAL)
  dLayout.setGravity(Gravity.CENTER)
  dLayout.setPadding(math.floor(40 * density), math.floor(40 * density), math.floor(40 * density), math.floor(30 * density))
  local bg = GradientDrawable()
  bg.setColor(Color.parseColor("#1E1E1E"))
  bg.setCornerRadius(math.floor(25 * density))
  dLayout.setBackground(bg)
  local titleTv = TextView(activity)
  titleTv.setText(title)
  titleTv.setTextColor(Color.parseColor("#FF5E7A"))
  titleTv.setTextSize(24)
  titleTv.setTypeface(Typeface.DEFAULT_BOLD)
  titleTv.setGravity(Gravity.CENTER)
  dLayout.addView(titleTv)
  local msgTv = TextView(activity)
  msgTv.setText(msg)
  msgTv.setTextColor(Color.WHITE)
  msgTv.setTextSize(16)
  msgTv.setGravity(Gravity.CENTER)
  msgTv.setPadding(0, math.floor(20 * density), 0, math.floor(20 * density))
  dLayout.addView(msgTv)
  local btn = TextView(activity)
  btn.setText(btnText or "确 定")
  btn.setTextColor(Color.WHITE)
  btn.setTextSize(18)
  btn.setGravity(Gravity.CENTER)
  local btnBg = GradientDrawable()
  btnBg.setOrientation(GradientDrawable.Orientation.LEFT_RIGHT)
  btnBg.setColors({
    Color.parseColor("#FF7B5C"),
    Color.parseColor("#FF5E7A"),
    Color.parseColor("#C77DFF"),
  })
  btnBg.setCornerRadius(math.floor(15 * density))
  btn.setBackground(btnBg)
  local btnLp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, math.floor(50 * density))
  btnLp.topMargin = math.floor(20 * density)
  btn.setLayoutParams(btnLp)
  btn.setOnClickListener({
    onClick = function()
      dialog.dismiss()
      if callback then callback() end
    end
  })
  dLayout.addView(btn)
  dialog.setContentView(dLayout)
  dialog.getWindow().setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
  dialog.show()
end

local loadingDialog = nil
local function showLoadingDialog(msg)
  loadingDialog = Dialog(activity)
  loadingDialog.setCancelable(false)
  local dLayout = LinearLayout(activity)
  dLayout.setOrientation(LinearLayout.VERTICAL)
  dLayout.setGravity(Gravity.CENTER)
  dLayout.setPadding(math.floor(40 * density), math.floor(40 * density), math.floor(40 * density), math.floor(40 * density))
  local bg = GradientDrawable()
  bg.setColor(Color.parseColor("#1E1E1E"))
  bg.setCornerRadius(math.floor(25 * density))
  dLayout.setBackground(bg)
  local msgTv = TextView(activity)
  msgTv.setText(msg or "加载中...")
  msgTv.setTextColor(Color.WHITE)
  msgTv.setTextSize(16)
  msgTv.setGravity(Gravity.CENTER)
  dLayout.addView(msgTv)
  loadingDialog.setContentView(dLayout)
  loadingDialog.getWindow().setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
  loadingDialog.show()
end

local function dismissLoadingDialog()
  if loadingDialog then
    loadingDialog.dismiss()
    loadingDialog = nil
  end
end

function wToast(data)
  showCustomDialog("提示", data, "确定", nil)
end

local layout = LinearLayout(activity)
layout.setOrientation(LinearLayout.VERTICAL)
layout.setGravity(Gravity.CENTER)
layout.setBackgroundColor(Color.BLACK)
layout.setPadding(math.floor(40 * density), 0, math.floor(40 * density), 0)
activity.setContentView(layout)

local title = TextView(activity)
title.setText("秋宇Pro")
title.setTextSize(36)
title.setTypeface(Typeface.DEFAULT_BOLD)
title.setGravity(Gravity.CENTER)
local screenW = activity.getResources().getDisplayMetrics().widthPixels
local titlePaint = title.getPaint()
titlePaint.setShader(LinearGradient(0, 0, screenW - math.floor(80 * density), 0,
Color.parseColor("#FF7B5C"),
Color.parseColor("#C77DFF"),
Shader.TileMode.CLAMP))
layout.addView(title)

local input = EditText(activity)
input.setHint("请输入卡密")
input.setHintTextColor(Color.GRAY)
input.setTextColor(Color.WHITE)
input.setSingleLine(true)
input.setPadding(math.floor(20 * density), math.floor(15 * density), math.floor(20 * density), math.floor(15 * density))
local bgInput = GradientDrawable()
bgInput.setColor(Color.parseColor("#222222"))
bgInput.setCornerRadius(math.floor(15 * density))
bgInput.setStroke(1, Color.parseColor("#FF5E7A"))
input.setBackground(bgInput)
local lpInput = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
lpInput.topMargin = math.floor(30 * density)
input.setLayoutParams(lpInput)
layout.addView(input)

local btn = Button(activity)
btn.setText("验证卡密")
btn.setTextSize(18)
btn.setGravity(Gravity.CENTER)
local bgBtn = GradientDrawable()
bgBtn.setOrientation(GradientDrawable.Orientation.LEFT_RIGHT)
bgBtn.setColors({
  Color.parseColor("#FF7B5C"),
  Color.parseColor("#FF5E7A"),
  Color.parseColor("#C77DFF"),
})
bgBtn.setCornerRadius(math.floor(15 * density))
btn.setBackground(bgBtn)
btn.setTextColor(Color.WHITE)
local lpBtn = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
lpBtn.topMargin = math.floor(20 * density)
btn.setLayoutParams(lpBtn)
layout.addView(btn)

local unbindBtn = Button(activity)
unbindBtn.setText("解绑卡密")
unbindBtn.setTextSize(18)
unbindBtn.setGravity(Gravity.CENTER)
local bgUnbindBtn = GradientDrawable()
bgUnbindBtn.setOrientation(GradientDrawable.Orientation.LEFT_RIGHT)
bgUnbindBtn.setColors({
  Color.parseColor("#FF7B5C"),
  Color.parseColor("#FF5E7A"),
  Color.parseColor("#C77DFF"),
})
bgUnbindBtn.setCornerRadius(math.floor(15 * density))
unbindBtn.setBackground(bgUnbindBtn)
unbindBtn.setTextColor(Color.WHITE)
local lpUnbindBtn = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
lpUnbindBtn.topMargin = math.floor(10 * density)
unbindBtn.setLayoutParams(lpUnbindBtn)
layout.addView(unbindBtn)

local function tohex(num) return string.format("%08x", num) end
local function lrotate(num, bits) return ((num << bits) | (num >> (32 - bits))) & 0xFFFFFFFF end

function df9859de34f315efab237b04415f44e5d(message)
  local h0 = 0x67452301; local h1 = 0xEFCDAB89; local h2 = 0x98BADCFE; local h3 = 0x10325476; local h4 = 0xC3D2E1F0
  local original_length = #message; local bit_length = original_length * 8
  message = message .. string.char(0x80)
  while (#message + 8) % 64 ~= 0 do message = message .. string.char(0x00) end
  for i = 1, 8 do local byte = (bit_length >> (64 - i * 8)) & 0xFF; message = message .. string.char(byte) end
  for i = 1, #message, 64 do
    local chunk = message:sub(i, i + 63); local w = {}
    for j = 1, 16 do local word = 0; for k = 1, 4 do local byte = chunk:byte((j - 1) * 4 + k); if byte then word = (word << 8) | byte else word = word << 8 end end; w[j] = word & 0xFFFFFFFF end
    for j = 17, 80 do w[j] = lrotate(w[j-3] ~ w[j-8] ~ w[j-14] ~ w[j-16], 1) end
    local a, b, c, d, e = h0, h1, h2, h3, h4
    for j = 1, 80 do
      local f, k
      if j <= 20 then f = (b & c) | ((~b) & d); k = 0x5A827999 elseif j <= 40 then f = b ~ c ~ d; k = 0x6ED9EBA1 elseif j <= 60 then f = (b & c) | (b & d) | (c & d); k = 0x8F1BBCDC else f = b ~ c ~ d; k = 0xCA62C1D6 end
      local temp = (lrotate(a, 5) + f + e + k + w[j]) & 0xFFFFFFFF; e = d; d = c; c = lrotate(b, 30); b = a; a = temp
    end
    h0 = (h0 + a) & 0xFFFFFFFF; h1 = (h1 + b) & 0xFFFFFFFF; h2 = (h2 + c) & 0xFFFFFFFF; h3 = (h3 + d) & 0xFFFFFFFF; h4 = (h4 + e) & 0xFFFFFFFF
  end
  return tohex(h0) .. tohex(h1) .. tohex(h2) .. tohex(h3) .. tohex(h4)
end

local k = {0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5, 0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174, 0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da, 0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967, 0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85, 0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070, 0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3, 0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2}
local function rrotate(x, n) return ((x >> n) | (x << (32 - n))) & 0xFFFFFFFF end
local function rshift(x, n) return (x >> n) & 0xFFFFFFFF end
local function Ch(x, y, z) return (x & y) ~ ((~x) & z) end
local function Maj(x, y, z) return (x & y) ~ (x & z) ~ (y & z) end
local function Sigma0(x) return rrotate(x, 2) ~ rrotate(x, 13) ~ rrotate(x, 22) end
local function Sigma1(x) return rrotate(x, 6) ~ rrotate(x, 11) ~ rrotate(x, 25) end
local function sigma0(x) return rrotate(x, 7) ~ rrotate(x, 18) ~ rshift(x, 3) end
local function sigma1(x) return rrotate(x, 17) ~ rrotate(x, 19) ~ rshift(x, 10) end

function e4f53cbbf63e6921e4880fa1bed87888f(message)
  local h = {0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19}
  local original_length = #message; local bit_length = original_length * 8
  message = message .. string.char(0x80)
  while (#message + 8) % 64 ~= 0 do message = message .. string.char(0x00) end
  for i = 1, 8 do local byte = (bit_length >> (64 - i * 8)) & 0xFF; message = message .. string.char(byte) end
  for chunk_start = 1, #message, 64 do
    local chunk = message:sub(chunk_start, chunk_start + 63); local w = {}
    for i = 1, 16 do local word = 0; for j = 1, 4 do local byte = chunk:byte((i - 1) * 4 + j); if byte then word = (word << 8) | byte else word = word << 8 end end; w[i] = word & 0xFFFFFFFF end
    for i = 17, 64 do w[i] = (sigma1(w[i-2]) + w[i-7] + sigma0(w[i-15]) + w[i-16]) & 0xFFFFFFFF end
    local a, b, c, d, e, f, g, h_temp = h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8]
    for i = 1, 64 do
      local T1 = (h_temp + Sigma1(e) + Ch(e, f, g) + k[i] + w[i]) & 0xFFFFFFFF
      local T2 = (Sigma0(a) + Maj(a, b, c)) & 0xFFFFFFFF
      h_temp = g; g = f; f = e; e = (d + T1) & 0xFFFFFFFF; d = c; c = b; b = a; a = (T1 + T2) & 0xFFFFFFFF
    end
    h[1] = (h[1] + a) & 0xFFFFFFFF; h[2] = (h[2] + b) & 0xFFFFFFFF; h[3] = (h[3] + c) & 0xFFFFFFFF; h[4] = (h[4] + d) & 0xFFFFFFFF; h[5] = (h[5] + e) & 0xFFFFFFFF; h[6] = (h[6] + f) & 0xFFFFFFFF; h[7] = (h[7] + g) & 0xFFFFFFFF; h[8] = (h[8] + h_temp) & 0xFFFFFFFF
  end
  local result = ""; for i = 1, 8 do result = result .. string.format("%08x", h[i]) end
  return result
end

function peaaf262643726d2a5900fd5706b48c7e(code)
  local HexTable = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"}
  local A = 0x67452301; local B = 0xefcdab89; local C = 0x98badcfe; local D = 0x10325476
  local S11, S12, S13, S14 = 7, 12, 17, 22
  local S21, S22, S23, S24 = 5, 9, 14, 20
  local S31, S32, S33, S34 = 4, 11, 16, 23
  local S41, S42, S43, S44 = 6, 10, 15, 21
  local function F(x,y,z) return (x & y) | ((~x) & z) end
  local function G(x,y,z) return (x & z) | (y & (~z)) end
  local function H(x,y,z) return x ~ y ~ z end
  local function I(x,y,z) return y ~ (x | (~z)) end
  local function FF(a,b,c,d,x,s,ac) local a = a + F(b,c,d) + x + ac; local a = (((a & 0xffffffff) << s) | ((a & 0xffffffff) >> 32 - s)) + b; return a & 0xffffffff end
  local function GG(a,b,c,d,x,s,ac) local a = a + G(b,c,d) + x + ac; local a = (((a & 0xffffffff) << s) | ((a & 0xffffffff) >> 32 - s)) + b; return a & 0xffffffff end
  local function HH(a,b,c,d,x,s,ac) local a = a + H(b,c,d) + x + ac; local a = (((a & 0xffffffff) << s) | ((a & 0xffffffff) >> 32 - s)) + b; return a & 0xffffffff end
  local function II(a,b,c,d,x,s,ac) local a = a + I(b,c,d) + x + ac; local a = (((a & 0xffffffff) << s) | ((a & 0xffffffff) >> 32 - s)) + b; return a & 0xffffffff end
  local function MD5StringFill(s)
    local len = s:len(); local mod512 = len * 8 % 512; local fillSize = (448 - mod512) // 8
    if mod512 > 448 then fillSize = (960 - mod512) // 8 end
    local rTab = {}; local byteIndex = 1
    for i = 1,len do local index = (i - 1) // 4 + 1; rTab[index] = rTab[index] or 0; rTab[index] = rTab[index] | (s:byte(i) << (byteIndex - 1) * 8); byteIndex = byteIndex + 1; if byteIndex == 5 then byteIndex = 1 end end
    local b0x80 = false; local tLen = #rTab
    if byteIndex ~= 1 then rTab[tLen] = rTab[tLen] | 0x80 << (byteIndex - 1) * 8; b0x80 = true end
    for i = 1,fillSize // 4 do if not b0x80 and i == 1 then rTab[tLen + i] = 0x80 else rTab[tLen + i] = 0x0 end end
    local bitLen = math.floor(len * 8); local tLen = #rTab
    rTab[tLen + 1] = bitLen & 0xffffffff; rTab[tLen + 2] = bitLen >> 32
    return rTab
  end
  local function w1c79ab98e2eb08a803da78a56433afb9(s)
    local fillTab = MD5StringFill(s); local result = {A,B,C,D}
    for i = 1,#fillTab // 16 do
      local a = result[1]; local b = result[2]; local c = result[3]; local d = result[4]; local offset = (i - 1) * 16 + 1
      local a = FF(a, b, c, d, fillTab[offset + 0], S11, 0xd76aa478); local d = FF(d, a, b, c, fillTab[offset + 1], S12, 0xe8c7b756); local c = FF(c, d, a, b, fillTab[offset + 2], S13, 0x242070db); local b = FF(b, c, d, a, fillTab[offset + 3], S14, 0xc1bdceee)
      local a = FF(a, b, c, d, fillTab[offset + 4], S11, 0xf57c0faf); local d = FF(d, a, b, c, fillTab[offset + 5], S12, 0x4787c62a); local c = FF(c, d, a, b, fillTab[offset + 6], S13, 0xa8304613); local b = FF(b, c, d, a, fillTab[offset + 7], S14, 0xfd469501)
      local a = FF(a, b, c, d, fillTab[offset + 8], S11, 0x698098d8); local d = FF(d, a, b, c, fillTab[offset + 9], S12, 0x8b44f7af); local c = FF(c, d, a, b, fillTab[offset + 10], S13, 0xffff5bb1); local b = FF(b, c, d, a, fillTab[offset + 11], S14, 0x895cd7be)
      local a = FF(a, b, c, d, fillTab[offset + 12], S11, 0x6b901122); local d = FF(d, a, b, c, fillTab[offset + 13], S12, 0xfd987193); local c = FF(c, d, a, b, fillTab[offset + 14], S13, 0xa679438e); local b = FF(b, c, d, a, fillTab[offset + 15], S14, 0x49b40821)
      local a = GG(a, b, c, d, fillTab[offset + 1], S21, 0xf61e2562); local d = GG(d, a, b, c, fillTab[offset + 6], S22, 0xc040b340); local c = GG(c, d, a, b, fillTab[offset + 11], S23, 0x265e5a51); local b = GG(b, c, d, a, fillTab[offset + 0], S24, 0xe9b6c7aa)
      local a = GG(a, b, c, d, fillTab[offset + 5], S21, 0xd62f105d); local d = GG(d, a, b, c, fillTab[offset + 10], S22, 0x2441453); local c = GG(c, d, a, b, fillTab[offset + 15], S23, 0xd8a1e681); local b = GG(b, c, d, a, fillTab[offset + 4], S24, 0xe7d3fbc8)
      local a = GG(a, b, c, d, fillTab[offset + 9], S21, 0x21e1cde6); local d = GG(d, a, b, c, fillTab[offset + 14], S22, 0xc33707d6); local c = GG(c, d, a, b, fillTab[offset + 3], S23, 0xf4d50d87); local b = GG(b, c, d, a, fillTab[offset + 8], S24, 0x455a14ed)
      local a = GG(a, b, c, d, fillTab[offset + 13], S21, 0xa9e3e905); local d = GG(d, a, b, c, fillTab[offset + 2], S22, 0xfcefa3f8); local c = GG(c, d, a, b, fillTab[offset + 7], S23, 0x676f02d9); local b = GG(b, c, d, a, fillTab[offset + 12], S24, 0x8d2a4c8a)
      local a = HH(a, b, c, d, fillTab[offset + 5], S31, 0xfffa3942); local d = HH(d, a, b, c, fillTab[offset + 8], S32, 0x8771f681); local c = HH(c, d, a, b, fillTab[offset + 11], S33, 0x6d9d6122); local b = HH(b, c, d, a, fillTab[offset + 14], S34, 0xfde5380c)
      local a = HH(a, b, c, d, fillTab[offset + 1], S31, 0xa4beea44); local d = HH(d, a, b, c, fillTab[offset + 4], S32, 0x4bdecfa9); local c = HH(c, d, a, b, fillTab[offset + 7], S33, 0xf6bb4b60); local b = HH(b, c, d, a, fillTab[offset + 10], S34, 0xbebfbc70)
      local a = HH(a, b, c, d, fillTab[offset + 13], S31, 0x289b7ec6); local d = HH(d, a, b, c, fillTab[offset + 0], S32, 0xeaa127fa); local c = HH(c, d, a, b, fillTab[offset + 3], S33, 0xd4ef3085); local b = HH(b, c, d, a, fillTab[offset + 6], S34, 0x4881d05)
      local a = HH(a, b, c, d, fillTab[offset + 9], S31, 0xd9d4d039); local d = HH(d, a, b, c, fillTab[offset + 12], S32, 0xe6db99e5); local c = HH(c, d, a, b, fillTab[offset + 15], S33, 0x1fa27cf8); local b = HH(b, c, d, a, fillTab[offset + 2], S34, 0xc4ac5665)
      local a = II(a, b, c, d, fillTab[offset + 0], S41, 0xf4292244); local d = II(d, a, b, c, fillTab[offset + 7], S42, 0x432aff97); local c = II(c, d, a, b, fillTab[offset + 14], S43, 0xab9423a7); local b = II(b, c, d, a, fillTab[offset + 5], S44, 0xfc93a039)
      local a = II(a, b, c, d, fillTab[offset + 12], S41, 0x655b59c3); local d = II(d, a, b, c, fillTab[offset + 3], S42, 0x8f0ccc92); local c = II(c, d, a, b, fillTab[offset + 10], S43, 0xffeff47d); local b = II(b, c, d, a, fillTab[offset + 1], S44, 0x85845dd1)
      local a = II(a, b, c, d, fillTab[offset + 8], S41, 0x6fa87e4f); local d = II(d, a, b, c, fillTab[offset + 15], S42, 0xfe2ce6e0); local c = II(c, d, a, b, fillTab[offset + 6], S43, 0xa3014314); local b = II(b, c, d, a, fillTab[offset + 13], S44, 0x4e0811a1)
      local a = II(a, b, c, d, fillTab[offset + 4], S41, 0xf7537e82); local d = II(d, a, b, c, fillTab[offset + 11], S42, 0xbd3af235); local c = II(c, d, a, b, fillTab[offset + 2], S43, 0x2ad7d2bb); local b = II(b, c, d, a, fillTab[offset + 9], S44, 0xeb86d391)
      result[1] = result[1] + a; result[2] = result[2] + b; result[3] = result[3] + c; result[4] = result[4] + d
      result[1] = result[1] & 0xffffffff; result[2] = result[2] & 0xffffffff; result[3] = result[3] & 0xffffffff; result[4] = result[4] & 0xffffffff
    end
    local retStr = ''; for i = 1,4 do for _ = 1,4 do local temp = result[i] & 0x0F; local str = HexTable[temp + 1]; result[i] = result[i] >> 4; local temp = result[i] & 0x0F; retStr = retStr .. HexTable[temp + 1] .. str; result[i] = result[i] >> 4 end end
    return string.lower(retStr)
  end
  return w1c79ab98e2eb08a803da78a56433afb9(code)
end

local function ZZMathBit_xorBit(left, right) return (left + right) == 1 and 1 or 0 end
local function ZZMathBit_base(left, right, op)
  if left < right then left, right = right, left end
  local res = 0; local shift = 1
  while left ~= 0 do local ra = left % 2; local rb = right % 2; res = shift * op(ra, rb) + res; shift = shift * 2; left = math.modf(left / 2); right = math.modf(right / 2) end
  return res
end
local function ZZMathBit_xorOp(left, right) return ZZMathBit_base(left, right, ZZMathBit_xorBit) end
local function KSA(key)
  local keyLen = string.len(key); local schedule = {}; local keyByte = {}
  for i = 0, 255 do schedule[i] = i end
  for i = 1, keyLen do keyByte[i - 1] = string.byte(key, i, i) end
  local j = 0
  for i = 0, 255 do j = (j + schedule[i] + keyByte[i % keyLen]) % 256; schedule[i], schedule[j] = schedule[j], schedule[i] end
  return schedule
end
local function PRGA(schedule, textLen)
  local i = 0; local j = 0; local k = {}
  for n = 1, textLen do i = (i + 1) % 256; j = (j + schedule[i]) % 256; schedule[i], schedule[j] = schedule[j], schedule[i]; k[n] = schedule[(schedule[i] + schedule[j]) % 256] end
  return k
end
local function output(schedule, text)
  local len = string.len(text); local res = {}
  for i = 1, len do local c = string.byte(text, i, i); res[i] = string.char(ZZMathBit_xorOp(schedule[i], c)) end
  return table.concat(res)
end
function e1a695d1286c432db04a2c3b4614af745(text, key)
  local textLen = string.len(text); local schedule = KSA(key); local k = PRGA(schedule, textLen); return output(k, text)
end
function odec07eea874ba5a0f2a6a16ef97acea2(str)
  local ret = ""; for i = 1, #str do ret = ret .. string.format("%02X", str:sub(i, i):byte()) end; return ret:lower()
end
function y1af2c0b8d7f7b707821e2f02f8577e0b(hexStr)
  local cleanStr = hexStr:gsub("[%s%p]", ""):upper(); local ret = ""; for i = 1, #cleanStr, 2 do ret = ret .. string.char(tonumber(cleanStr:sub(i, i + 1), 16)) end; return ret
end
local base64chars = {[0]='A',[1]='B',[2]='C',[3]='D',[4]='E',[5]='F',[6]='G',[7]='H',[8]='I',[9]='J',[10]='K',[11]='L',[12]='M',[13]='N',[14]='O',[15]='P',[16]='Q',[17]='R',[18]='S',[19]='T',[20]='U',[21]='V',[22]='W',[23]='X',[24]='Y',[25]='Z',[26]='a',[27]='b',[28]='c',[29]='d',[30]='e',[31]='f',[32]='g',[33]='h',[34]='i',[35]='j',[36]='k',[37]='l',[38]='m',[39]='n',[40]='o',[41]='p',[42]='q',[43]='r',[44]='s',[45]='t',[46]='u',[47]='v',[48]='w',[49]='x',[50]='y',[51]='z',[52]='0',[53]='1',[54]='2',[55]='3',[56]='4',[57]='5',[58]='6',[59]='7',[60]='8',[61]='9',[62]='-',[63]='_'}
function gc7086821f2e47c3c6b2d63b0b9d94340(data)
  local bytes = {}; local result = ""
  for i = 0, data:len()-1, 3 do
    for byte = 1, 3 do bytes[byte] = string.byte(data:sub(i+byte)) or 0 end
    result = string.format('%s%s%s%s%s', result, base64chars[ math.floor(bytes[1]/4) ] or "=", base64chars[(bytes[1] % 4) * 16 + math.floor(bytes[2] / 16)] or "=", ({[true] = base64chars[(bytes[2] % 16) * 4 + math.floor(bytes[3] / 64)] or "=", [false] = "="})[(data:len() - i) > 1], ({[true] = base64chars[(bytes[3] % 64)] or "=", [false] = "="})[(data:len(data) - i) > 2])
  end
  return result
end
local base64bytes = {['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['-']=62,['_']=63,['=']=nil}
function ub0f9422efda3c992f643e86868082129(data)
  local chars = {}; local result = ""
  for i = 0, data:len()-1, 4 do
    for c = 1, 4 do chars[c] = base64bytes[ (string.sub(data,(i+c),(i+c)) or "=") ] end
    result = string.format('%s%s%s%s', result, string.char(chars[1]*4 + math.floor(chars[2]/16)), ({[true] = string.char(((chars[2] or 0) % 16)*16 + math.floor((chars[3] or 0)/4)), [false] = ""})[chars[3] ~= nil], ({[true] = string.char(((chars[3] or 0)%4) * 64 + (chars[4] or 0)), [false] = ""})[chars[4] ~= nil])
  end
  return result
end
function ybeff9d24b4270a0487bbd220e2129cda(input, base64_chars)
  local output = ""; local padding = ""; local i = 1; local len = #input
  while i <= len do
    local b1 = string.byte(input, i); local b2 = string.byte(input, i + 1); local b3 = string.byte(input, i + 2)
    if not b2 then b2 = 0; padding = padding .. "=" end
    if not b3 then b3 = 0; padding = padding .. "=" end
    local combined = (b1 << 16) + (b2 << 8) + b3
    output = output .. base64_chars:sub(((combined >> 18) & 0x3F) + 1, ((combined >> 18) & 0x3F) + 1) .. base64_chars:sub(((combined >> 12) & 0x3F) + 1, ((combined >> 12) & 0x3F) + 1) .. base64_chars:sub(((combined >> 6) & 0x3F) + 1, ((combined >> 6) & 0x3F) + 1) .. base64_chars:sub((combined & 0x3F) + 1, (combined & 0x3F) + 1)
    i = i + 3
  end
  return output:sub(1, #output - #padding) .. padding
end
function e8c25571af8ff17c7b0d794c71621317e(input, base64_chars)
  local base64_decode_chars = {}
  for i = 1, #base64_chars do base64_decode_chars[base64_chars:sub(i, i)] = i - 1 end
  local padding = 0
  if input:sub(-1) == "=" then padding = padding + 1 end
  if input:sub(-2, -1) == "==" then padding = padding + 1 end
  local output = ""; local i = 1; local len = #input
  while i <= len - padding do
    local c1 = base64_decode_chars[input:sub(i, i)]; local c2 = base64_decode_chars[input:sub(i + 1, i + 1)]; local c3 = base64_decode_chars[input:sub(i + 2, i + 2)]; local c4 = base64_decode_chars[input:sub(i + 3, i + 3)]
    if not c3 then c3 = 0 end
    if not c4 then c4 = 0 end
    local combined = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4
    output = output .. string.char((combined >> 16) & 0xFF) .. string.char((combined >> 8) & 0xFF) .. string.char(combined & 0xFF)
    i = i + 4
  end
  if padding == 1 then output = output:sub(1, -2) elseif padding == 2 then output = output:sub(1, -3) end
  return output
end

local kmPath = "/sdcard/.km"
local kami = io.open(kmPath, "r")
if kami ~= nil then input.setText(kami:read("*a")); kami:close() end

local j8ac0f93f287cccbe76e63309d2bb958f = "https://wy.llua.cn/v2/"
import "cjson"
import "android.provider.Settings$Secure"

Http.post(j8ac0f93f287cccbe76e63309d2bb958f .. "fb14a89c07a6df5ab9078e5f2cffcc03", odec07eea874ba5a0f2a6a16ef97acea2(gc7086821f2e47c3c6b2d63b0b9d94340(gc7086821f2e47c3c6b2d63b0b9d94340(odec07eea874ba5a0f2a6a16ef97acea2(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(ybeff9d24b4270a0487bbd220e2129cda(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(gc7086821f2e47c3c6b2d63b0b9d94340("id=62UuRkzf06r"), "e05aab8be12cf9e22046bafa0c62f")), "QeK/thHMvEjxSpkUmrJnoR1fqBLWsDwCN0u5V9zFbGOgyc28Y7ZP3lA4+6ITidXa"), "v5eb40e72a2ce205ce16c4c60c3b711")))))), function(code, data)
  if code == 200 then
    local data = cjson.decode(e1a695d1286c432db04a2c3b4614af745(y1af2c0b8d7f7b707821e2f02f8577e0b(data), "ca27c2aac169892b573d913dd21169b"))
    if data.code == 102 then
      showCustomDialog("提示", "未连接到服务器", "退出", function() activity.finish(); os.exit() end)
      task(3000, function() activity.finish(); os.exit(); while true end end)
     elseif data.code == 80860 then
      if type(data.msg.app_gg) ~= "userdata" and data.msg.app_gg ~= "" then
        showCustomDialog("公告", data.msg.app_gg, "已阅", nil)
      end
     else
      showCustomDialog("错误", "服务器连接异常", "确定", nil)
    end
   else
    showCustomDialog("网络异常", "请求失败，请检查网络", "确定", nil)
  end
end)

--[[Http.post(j8ac0f93f287cccbe76e63309d2bb958f .. "fb14a89c07a6df5ab9078e5f2cffcc03", odec07eea874ba5a0f2a6a16ef97acea2(gc7086821f2e47c3c6b2d63b0b9d94340(gc7086821f2e47c3c6b2d63b0b9d94340(odec07eea874ba5a0f2a6a16ef97acea2(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(ybeff9d24b4270a0487bbd220e2129cda(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(gc7086821f2e47c3c6b2d63b0b9d94340("id=V6575Z2z02e"), "e05aab8be12cf9e22046bafa0c62f")), "QeK/thHMvEjxSpkUmrJnoR1fqBLWsDwCN0u5V9zFbGOgyc28Y7ZP3lA4+6ITidXa"), "v5eb40e72a2ce205ce16c4c60c3b711")))))), function(code, data)
  if code == 200 then
    local data = cjson.decode(e1a695d1286c432db04a2c3b4614af745(y1af2c0b8d7f7b707821e2f02f8577e0b(data), "ca27c2aac169892b573d913dd21169b"))
    if data.code == 52937 then
      local currentVersion = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionName
      if currentVersion ~= data.msg.version then
        if string.find(tostring(data.msg.updateurl), "http") == nil then
          showCustomDialog("提示", "后台没有配置正确的更新地址", "确定", nil)
         else
          if data.msg.updatemust == "y" then isUp = true end
          local updateMsg = "当前版本:" .. currentVersion .. "\n最新版本:" .. data.msg.version .. "\n更新内容:" .. tostring(data.msg.updateshow)
          showCustomDialog("发现新版本", updateMsg, "下载更新", function()
            activity.startActivity(Intent("android.intent.action.VIEW", Uri.parse(data.msg.updateurl)))
          end)
        end
      end
    end
   else
    showCustomDialog("网络异常", "更新检查失败", "确定", nil)
  end
end)
]]
pending_install_id = nil

function onResume()
  if pending_install_id then
    local pm = activity.getPackageManager()
    if pm.canRequestPackageInstalls() then
      local dm = activity.getSystemService(activity.DOWNLOAD_SERVICE)
      local uri = dm.getUriForDownloadedFile(pending_install_id)
      if uri ~= nil then
        local installIntent = Intent("android.intent.action.VIEW")
        installIntent.setDataAndType(uri, "application/vnd.android.package-archive")
        installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.startActivity(installIntent)
        pending_install_id = nil
      end
     else
      showCustomDialog("提示", "您还未授权安装未知应用", "去设置", function()
        local installPermissionIntent = Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES")
        installPermissionIntent.setData(Uri.parse("package:" .. activity.getPackageName()))
        activity.startActivity(installPermissionIntent)
      end, "取消", nil)
    end
  end
end

Http.post(j8ac0f93f287cccbe76e63309d2bb958f .. "fb14a89c07a6df5ab9078e5f2cffcc03", odec07eea874ba5a0f2a6a16ef97acea2(gc7086821f2e47c3c6b2d63b0b9d94340(gc7086821f2e47c3c6b2d63b0b9d94340(odec07eea874ba5a0f2a6a16ef97acea2(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(ybeff9d24b4270a0487bbd220e2129cda(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(gc7086821f2e47c3c6b2d63b0b9d94340("id=V6575Z2z02e"), "e05aab8be12cf9e22046bafa0c62f")), "QeK/thHMvEjxSpkUmrJnoR1fqBLWsDwCN0u5V9zFbGOgyc28Y7ZP3lA4+6ITidXa"), "v5eb40e72a2ce205ce16c4c60c3b711")))))), function(code, data)
  if code == 200 then
    local data = cjson.decode(e1a695d1286c432db04a2c3b4614af745(y1af2c0b8d7f7b707821e2f02f8577e0b(data), "ca27c2aac169892b573d913dd21169b"))
    if data.code == 52937 then
      local currentVersion = activity.getPackageManager().getPackageInfo(activity.getPackageName(), 0).versionName
      if currentVersion ~= data.msg.version then
        if string.find(tostring(data.msg.updateurl), "http") == nil then
          showCustomDialog("提示", "后台没有配置正确的更新地址", "确定", nil)
         else
          if data.msg.updatemust == "y" then isUp = true end
          local updateMsg = "当前版本:" .. currentVersion .. "\n最新版本:" .. data.msg.version .. "\n更新内容:" .. tostring(data.msg.updateshow)
          showCustomDialog("发现新版本", updateMsg, "下载更新", function()
            showCustomDialog("下载提醒", "正在准备下载安装包，请留意通知栏进度...", "下载", function()
              os.remove("/storage/emulated/0/Download/update.apk")
              local DownloadManager = luajava.bindClass("android.app.DownloadManager")
              local Uri = luajava.bindClass("android.net.Uri")
              local Environment = luajava.bindClass("android.os.Environment")
              local Request = luajava.bindClass("android.app.DownloadManager$Request")
              local Intent = luajava.bindClass("android.content.Intent")
              local File = luajava.bindClass("java.io.File")
              local dm = activity.getSystemService(activity.DOWNLOAD_SERVICE)
              local request = Request(Uri.parse(data.msg.updateurl))
              request.setDestinationInExternalPublicDir(Environment.DIRECTORY_DOWNLOADS, "update.apk")
              request.setNotificationVisibility(Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED)
              local downloadId = dm.enqueue(request)

              local heartbeat_check
              heartbeat_check = function()
                local f = File("/storage/emulated/0/Download/update.apk")
                if f.exists() and f.length() > 0 then
                  local pm = activity.getPackageManager()
                  if not pm.canRequestPackageInstalls() then
                    pending_install_id = downloadId
                    showCustomDialog("提示", "请允许安装未知应用后才能安装", "去授权", function()
                      local installPermissionIntent = Intent("android.settings.MANAGE_UNKNOWN_APP_SOURCES")
                      installPermissionIntent.setData(Uri.parse("package:" .. activity.getPackageName()))
                      activity.startActivity(installPermissionIntent)
                    end, "取消", nil)
                   else
                    local uri = dm.getUriForDownloadedFile(downloadId)
                    if uri ~= nil then
                      local installIntent = Intent("android.intent.action.VIEW")
                      installIntent.setDataAndType(uri, "application/vnd.android.package-archive")
                      installIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                      installIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                      showCustomDialog("下载完成", "是否安装？", "安装", function()
                        activity.startActivity(installIntent)
                      end, "取消", nil)
                     else
                      showCustomDialog("错误", "获取安装包安全路径失败", "确定", nil)
                    end
                  end
                  return
                end
                task(2000, heartbeat_check)
              end
              task(2000, heartbeat_check)
            end)
          end)
        end
      end
    end
   else
    showCustomDialog("网络异常", "更新检查失败", "确定", nil)
  end
end)


isUp = false

local function unbind()
  local ja12ca71e6b7cc2fa8d2d966600234865 = Secure.getString(activity.getContentResolver(), Secure.ANDROID_ID)
  local g813a2531041668abb7532ce825887015 = input.getText().toString()
  local m645df26106d6265cdacd5cf570613f09 = os.time()
  local l1f7cc646f6305b02391fe53ac641bc82 = math.random(1000,99999) .. os.time()

  if g813a2531041668abb7532ce825887015 == "" then
    showCustomDialog("提示", "卡密不可为空", "确定", nil)
    return
  end

  local oc956d8bf6c743df5dbe5667f4661a407 = peaaf262643726d2a5900fd5706b48c7e("kami=" .. g813a2531041668abb7532ce825887015 .. "&markcode=" .. ja12ca71e6b7cc2fa8d2d966600234865 .. "&t=" .. m645df26106d6265cdacd5cf570613f09 .. "&q34ea55afec7fc4b60d4f90af9a")

  showLoadingDialog("解绑中...")
  Http.post(j8ac0f93f287cccbe76e63309d2bb958f .. "fb14a89c07a6df5ab9078e5f2cffcc03",
  odec07eea874ba5a0f2a6a16ef97acea2(gc7086821f2e47c3c6b2d63b0b9d94340(gc7086821f2e47c3c6b2d63b0b9d94340(odec07eea874ba5a0f2a6a16ef97acea2(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(ybeff9d24b4270a0487bbd220e2129cda(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(gc7086821f2e47c3c6b2d63b0b9d94340("id=GZsadD8VdsB&kami=" .. g813a2531041668abb7532ce825887015 .. "&markcode=" .. ja12ca71e6b7cc2fa8d2d966600234865 .. "&t=" .. m645df26106d6265cdacd5cf570613f09 .. "&sign=" .. oc956d8bf6c743df5dbe5667f4661a407 .. "&value=" .. l1f7cc646f6305b02391fe53ac641bc82 .. ""), "e05aab8be12cf9e22046bafa0c62f")), "QeK/thHMvEjxSpkUmrJnoR1fqBLWsDwCN0u5V9zFbGOgyc28Y7ZP3lA4+6ITidXa"), "v5eb40e72a2ce205ce16c4c60c3b711")))))), function(code, data)
    dismissLoadingDialog()
    if code == 200 then
      local data = cjson.decode(e1a695d1286c432db04a2c3b4614af745(y1af2c0b8d7f7b707821e2f02f8577e0b(data), "ca27c2aac169892b573d913dd21169b"))
      if data.code == 66164 then
        showCustomDialog("解绑成功", "剩余可解绑次数:" .. tointeger(data.msg.num), "确定", nil)
       else
        showCustomDialog("解绑失败", tostring(data.msg), "确定", nil)
      end
     else
      showCustomDialog("网络异常", "解绑请求失败，请检查网络", "确定", nil)
    end
  end)
end

btn.setOnClickListener({
  onClick = function()
    local ja12ca71e6b7cc2fa8d2d966600234865 = Secure.getString(activity.getContentResolver(), Secure.ANDROID_ID)
    local g813a2531041668abb7532ce825887015 = input.getText().toString()
    local m645df26106d6265cdacd5cf570613f09 = os.time()
    local l1f7cc646f6305b02391fe53ac641bc82 = math.random(1000,99999) .. os.time()
    if isUp then showCustomDialog("提示", "强制更新，请先更新后使用", "确定", nil); return end
    if g813a2531041668abb7532ce825887015 == "" then showCustomDialog("提示", "卡密不可为空", "确定", nil); return end

    local oc956d8bf6c743df5dbe5667f4661a407 = peaaf262643726d2a5900fd5706b48c7e("kami=" .. g813a2531041668abb7532ce825887015 .. "&markcode=" .. ja12ca71e6b7cc2fa8d2d966600234865 .. "&t=" .. m645df26106d6265cdacd5cf570613f09 .. "&q34ea55afec7fc4b60d4f90af9a")
    showLoadingDialog("登录中...")

    Http.post(j8ac0f93f287cccbe76e63309d2bb958f .. "fb14a89c07a6df5ab9078e5f2cffcc03", odec07eea874ba5a0f2a6a16ef97acea2(gc7086821f2e47c3c6b2d63b0b9d94340(gc7086821f2e47c3c6b2d63b0b9d94340(odec07eea874ba5a0f2a6a16ef97acea2(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(ybeff9d24b4270a0487bbd220e2129cda(odec07eea874ba5a0f2a6a16ef97acea2(e1a695d1286c432db04a2c3b4614af745(gc7086821f2e47c3c6b2d63b0b9d94340("id=58sl5SaK6Z1&kami=" .. g813a2531041668abb7532ce825887015 .. "&markcode=" .. ja12ca71e6b7cc2fa8d2d966600234865 .. "&t=" .. m645df26106d6265cdacd5cf570613f09 .. "&sign=" .. oc956d8bf6c743df5dbe5667f4661a407 .. "&value=" .. l1f7cc646f6305b02391fe53ac641bc82 .. ""), "e05aab8be12cf9e22046bafa0c62f")), "QeK/thHMvEjxSpkUmrJnoR1fqBLWsDwCN0u5V9zFbGOgyc28Y7ZP3lA4+6ITidXa"), "v5eb40e72a2ce205ce16c4c60c3b711")))))), function(code, e83b5600c80af8d44d99790827864c954)
      dismissLoadingDialog()
      if code == 200 then
        local e83b5600c80af8d44d99790827864c954 = cjson.decode(e1a695d1286c432db04a2c3b4614af745(y1af2c0b8d7f7b707821e2f02f8577e0b(e8c25571af8ff17c7b0d794c71621317e(e8c25571af8ff17c7b0d794c71621317e(e1a695d1286c432db04a2c3b4614af745(y1af2c0b8d7f7b707821e2f02f8577e0b(e83b5600c80af8d44d99790827864c954), "e5a0fe9c5a0b817368a"), "guVZTi0Fnj1vtRz7WX5SC4eKIDpaxGmshOkwEP3cH69rl+bdMANqYyLUQ/f8Jo2B"), "THgjRQypLeDEdB6IWm3iNA78h024oFsbxCM/nJOSaVzUqt+rZvYlK5X1wPcufG9k")), "w50c0c19e53e9348391b52889"))
        if e83b5600c80af8d44d99790827864c954.o7d9a15197399472d9f35c10aa4634c4b == 95565 and e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.wac6653879b0979b4c70f463747162862 == "beafae3602850e0459b8f5cebf9622fc" then
          if e83b5600c80af8d44d99790827864c954.m3174c6c34aa2a1a5ae5d75807b3d3402 - m645df26106d6265cdacd5cf570613f09 > 30 or e83b5600c80af8d44d99790827864c954.m3174c6c34aa2a1a5ae5d75807b3d3402 - m645df26106d6265cdacd5cf570613f09 < -30 then
            showCustomDialog("提示", "设备时间不准", "确定", nil)
           else
            if e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.xb4e8e2aa5cae ~= peaaf262643726d2a5900fd5706b48c7e(df9859de34f315efab237b04415f44e5d("" .. m645df26106d6265cdacd5cf570613f09 .. "" .. "q34ea55afec7fc4b60d4f90af9a" .. "" .. m645df26106d6265cdacd5cf570613f09 .. "")) or e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.nb4ff32db06e2a9 ~= peaaf262643726d2a5900fd5706b48c7e(df9859de34f315efab237b04415f44e5d(df9859de34f315efab237b04415f44e5d("" .. l1f7cc646f6305b02391fe53ac641bc82 .. "" .. m645df26106d6265cdacd5cf570613f09 .. "" .. m645df26106d6265cdacd5cf570613f09 .. "" .. "q34ea55afec7fc4b60d4f90af9a" .. ""))) or e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.ze6d99d9bfbbbf4 ~= e4f53cbbf63e6921e4880fa1bed87888f(df9859de34f315efab237b04415f44e5d("" .. tointeger(e83b5600c80af8d44d99790827864c954.o7d9a15197399472d9f35c10aa4634c4b) .. "" .. tointeger(e83b5600c80af8d44d99790827864c954.o7d9a15197399472d9f35c10aa4634c4b) .. "" .. tointeger(e83b5600c80af8d44d99790827864c954.m3174c6c34aa2a1a5ae5d75807b3d3402) .. "")) then
              showCustomDialog("提示", "校验失败", "确定", nil)
              return
            end

            local successMsg = ""
            if e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.b1fa2e9909708a5cc88dd0c0e7add8899 == "single" then
              successMsg = "登录成功\n剩余登录次数:" .. tointeger(e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.v6a3c469ab83c8b7b0a32dae84351dab9)
             else
              successMsg = "登录成功\n到期时间:" .. os.date("%Y-%m-%d %H:%M:%S", e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f.ob041054826610971a3ea6160ef5286e7)
            end

            io.open(kmPath, "w"):write(input.getText().toString()):close()
            showCustomDialog("成功", successMsg, "进入软件", function()
              -- 写入登录状态到 SharedPreferences（绝对稳定）
              local sp = activity.getSharedPreferences("login", 0)
              local editor = sp.edit()
              editor.putString("status", "true")
              editor.commit()

              activity.newActivity("qiuyuPro")
            end)
          end
         else
          showCustomDialog("失败", e83b5600c80af8d44d99790827864c954.s02dc523116ed5d4c3e3094a5ea34e68f, "确定", nil)
        end
       else
        showCustomDialog("网络异常", "登录请求失败，请检查网络", "确定", nil)
      end
    end)
  end
})

unbindBtn.setOnClickListener({
  onClick = function()
    unbind()
  end
})

