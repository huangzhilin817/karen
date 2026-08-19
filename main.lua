require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "AndLua"
import "java.net.URL"
import "java.net.HttpURLConnection"
import "java.io.InputStream"
import "android.graphics.BitmapFactory"
import "android.graphics.drawable.BitmapDrawable"
import "android.os.StrictMode"
import "android.text.InputType"
import "android.text.method.PasswordTransformationMethod"
import "android.util.DisplayMetrics"
local Builder = luajava.bindClass("android.os.StrictMode$ThreadPolicy$Builder")
local policy = Builder().permitNetwork().build()
StrictMode.setThreadPolicy(policy)

local window = activity.getWindow()
local View = luajava.bindClass("android.view.View")
local Build = luajava.bindClass("android.os.Build")
local WindowManager = luajava.bindClass("android.view.WindowManager")

if Build.VERSION.SDK_INT >= 21 then
  window.clearFlags(WindowManager.LayoutParams.FLAG_TRANSLUCENT_STATUS)
  window.addFlags(WindowManager.LayoutParams.FLAG_DRAWS_SYSTEM_BAR_BACKGROUNDS)
  window.setStatusBarColor(0x00000000)
  window.setNavigationBarColor(0x00000000)
  local flags = View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
  if Build.VERSION.SDK_INT >= 23 then
    flags = flags | View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
  end
  if Build.VERSION.SDK_INT >= 26 then
    flags = flags | View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
  end
  window.getDecorView().setSystemUiVisibility(flags)
  if Build.VERSION.SDK_INT >= 28 then
    local LayoutParams = luajava.bindClass("android.view.WindowManager$LayoutParams")
    local params = window.getAttributes()
    params.layoutInDisplayCutoutMode = LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
    window.setAttributes(params)
  end
end

local FREE_MODE = "开"

local CARD_LIST = {
  { key = "k", expire = "0", status = "开" },
  { key = "输入卡密", expire = "2026.12.31.23.59", status = "开" },
  { key = "输入卡密", expire = "2026.08.19.10.40", status = "开" },
}

local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local ImageView = luajava.bindClass("android.widget.ImageView")
local ScaleType = luajava.bindClass("android.widget.ImageView$ScaleType")
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local Dialog = luajava.bindClass("android.app.Dialog")
local ColorDrawable = luajava.bindClass("android.graphics.drawable.ColorDrawable")
local Window = luajava.bindClass("android.view.Window")
local DisplayMetrics = luajava.bindClass("android.util.DisplayMetrics")

local root = FrameLayout(activity)

local iv = ImageView(activity)
iv.setScaleType(ScaleType.CENTER_CROP)
local matchParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
iv.setLayoutParams(matchParams)
root.addView(iv)

local verifyLayout = LinearLayout(activity)
verifyLayout.setLayoutParams(matchParams)
verifyLayout.setBackgroundColor(0x00000000)
verifyLayout.setGravity(Gravity.CENTER)
verifyLayout.setOrientation(LinearLayout.VERTICAL)

local card = LinearLayout(activity)
card.setOrientation(LinearLayout.VERTICAL)
card.setGravity(Gravity.CENTER)
card.setPadding(50, 50, 50, 50)

local cardBg = GradientDrawable()
cardBg.setColor(0x88000000)
cardBg.setCornerRadius(30)
card.setBackgroundDrawable(cardBg)

local cardParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
cardParams.gravity = Gravity.CENTER
cardParams.setMargins(60, 0, 60, 0)
card.setLayoutParams(cardParams)

local title = TextView(activity)
title.setText("验证卡密")
title.setTextColor(0xFFFFFFFF)
title.setTextSize(24)
title.setTypeface(Typeface.DEFAULT_BOLD)
title.setGravity(Gravity.CENTER)
local titleParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT)
titleParams.setMargins(0, 0, 0, 30)
title.setLayoutParams(titleParams)

local et = EditText(activity)
et.setHint("请输入卡密")
et.setInputType(InputType.TYPE_CLASS_TEXT)
et.setTransformationMethod(PasswordTransformationMethod.getInstance())
et.setTextColor(0xFFFFFFFF)
et.setHintTextColor(0x88FFFFFF)
et.setTextSize(16)
et.setGravity(Gravity.CENTER)
et.setSingleLine(true)

local InputFilter = luajava.bindClass("android.text.InputFilter")
et.setFilters({
  luajava.createProxy("android.text.InputFilter", {
    filter = function(source, s_start, s_end, dest, d_start, d_end)
      local s = tostring(source)
      local filtered = s:gsub("[^%w]", "")
      if filtered ~= s then return filtered end
      return nil
    end
  })
})

local etBg = GradientDrawable()
etBg.setStroke(2, 0x66FFFFFF)
etBg.setCornerRadius(16)
etBg.setColor(0x00FFFFFF)
et.setBackgroundDrawable(etBg)
et.setPadding(30, 20, 30, 20)
local etParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT)
etParams.setMargins(0, 0, 0, 30)
et.setLayoutParams(etParams)

local btn = Button(activity)
btn.setText("确认验证")
btn.setTextColor(0xFFFFFFFF)
btn.setTextSize(16)
btn.setAllCaps(false)
btn.setGravity(Gravity.CENTER)

local btnBg = GradientDrawable()
btnBg.setColor(0xFF2196F3)
btnBg.setCornerRadius(16)
btn.setBackgroundDrawable(btnBg)
btn.setPadding(0, 18, 0, 18)
btn.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

card.addView(title)
card.addView(et)
card.addView(btn)
verifyLayout.addView(card)
root.addView(verifyLayout)
activity.setContentView(root)

local function showGlassDialog(msg, isSuccess)
  local dialog = Dialog(activity)
  dialog.requestWindowFeature(Window.FEATURE_NO_TITLE)
  dialog.setCancelable(false)
  dialog.setCanceledOnTouchOutside(false)

  local glassLayout = LinearLayout(activity)
  glassLayout.setOrientation(LinearLayout.VERTICAL)
  glassLayout.setGravity(Gravity.CENTER)
  glassLayout.setPadding(40, 40, 40, 40)

  local glassBg = GradientDrawable()
  glassBg.setColor(0xCCF5F5F5)
  glassBg.setCornerRadius(28)
  glassLayout.setBackgroundDrawable(glassBg)

  local dialogTitle = TextView(activity)
  dialogTitle.setText("验证")
  dialogTitle.setTextColor(0xFF333333)
  dialogTitle.setTextSize(22)
  dialogTitle.setTypeface(Typeface.DEFAULT_BOLD)
  dialogTitle.setGravity(Gravity.CENTER)

  local dialogMsg = TextView(activity)
  dialogMsg.setText(msg)
  dialogMsg.setTextColor(0xFF555555)
  dialogMsg.setTextSize(18)
  dialogMsg.setGravity(Gravity.CENTER)

  local dialogBtn = Button(activity)
  dialogBtn.setText("确认")
  dialogBtn.setTextColor(0xFFFFFFFF)
  dialogBtn.setTextSize(16)
  dialogBtn.setAllCaps(false)

  local btnBg = GradientDrawable()
  btnBg.setColor(0xFF2196F3)
  btnBg.setCornerRadius(16)
  dialogBtn.setBackgroundDrawable(btnBg)
  dialogBtn.setPadding(0, 16, 0, 16)
  dialogBtn.setLayoutParams(LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

  dialogBtn.setOnClickListener({
    onClick = function()
      dialog.dismiss()
      if isSuccess then
        verifyLayout.setVisibility(View.GONE)
        -- 成功回调：可在此处加跳转或其他操作

        import "karen"
      end
    end
  })

  glassLayout.addView(dialogTitle)
  glassLayout.addView(dialogMsg)
  glassLayout.addView(dialogBtn)

  dialog.setContentView(glassLayout)

  local windowManager = dialog.getWindow()
  windowManager.setBackgroundDrawable(ColorDrawable(0x00000000))
  local dm = DisplayMetrics()
  activity.getWindowManager().getDefaultDisplay().getMetrics(dm)
  local screenWidth = dm.widthPixels
  windowManager.setLayout((screenWidth * 0.85), WindowManager.LayoutParams.WRAP_CONTENT)
  windowManager.setGravity(Gravity.CENTER)

  dialog.show()
end

local function loadBg()
  local urlStr = "https://gd-hbimg.huaban.com/e4695f60ef48ef4b99c85381c0d564923ce4be1c1c96a7-JTX53j_fw658webp"
  local success, result = pcall(function()
    local url = URL(urlStr)
    local conn = url.openConnection()
    conn.setConnectTimeout(5000)
    conn.setReadTimeout(5000)
    conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36")
    conn.connect()
    local input = conn.getInputStream()
    local bmp = BitmapFactory.decodeStream(input)
    input.close()
    return bmp
  end)
  if success and result then
    iv.setImageBitmap(result)
   else
    root.setBackgroundColor(0xFFF2F2F2)
    if not success then
      showGlassDialog("网络异常", false)
     else
      showGlassDialog("图片解码失败", false)
    end
  end
end

local function formatExpire(expire)
  if expire == "0" then return "永久" end
  local str = expire
  if expire:find("%.") then
    local parts = {}
    for p in expire:gmatch("[^.]+") do table.insert(parts, p) end
    if #parts == 5 then
      str = string.format("%04d-%02d-%02d %02d:%02d", tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4]), tonumber(parts[5]))
     elseif #parts == 3 then
      str = string.format("%04d-%02d-%02d", tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]))
    end
  end
  return str
end

local function checkCard(input)
  if FREE_MODE == "开" then
    return true, "验证成功，免费模式"
  end

  for _, item in ipairs(CARD_LIST) do
    if input == item.key then
      if item.status ~= "开" then return false, "卡密已被禁用" end
      local expire = item.expire
      if expire == "0" then return true, "验证成功，到期时间: 永久" end
      local expireStr = formatExpire(expire)
      local now = os.date("%Y-%m-%d %H:%M")
      if expireStr:find(" ") then
        if now > expireStr then return false, "卡密已过期" end
        return true, "验证成功，到期时间: " .. expireStr
       else
        if os.date("%Y-%m-%d") > expireStr then return false, "卡密已过期" end
        return true, "验证成功，到期时间: " .. expireStr
      end
    end
  end
  return false, "卡密不存在"
end

loadBg()

btn.setOnClickListener(function()
  local input = et.getText().toString()
  if input == "" then
    showGlassDialog("卡密不允许为空", false)
    return
  end
  local ok, msg = checkCard(input)
  if ok then
    showGlassDialog(msg, true)
   else
    showGlassDialog(msg, false)
  end
end)
