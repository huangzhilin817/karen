require "import"
import "AndLua"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.*"
import "java.net.URL"
import "java.net.HttpURLConnection"
import "java.io.InputStream"
import "android.graphics.BitmapFactory"
import "android.graphics.drawable.BitmapDrawable"
import "android.os.StrictMode"
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

local LinearLayout = luajava.bindClass("android.widget.LinearLayout")
local FrameLayout = luajava.bindClass("android.widget.FrameLayout")
local ImageView = luajava.bindClass("android.widget.ImageView")
local ScaleType = luajava.bindClass("android.widget.ImageView$ScaleType")
local TextView = luajava.bindClass("android.widget.TextView")
local Gravity = luajava.bindClass("android.view.Gravity")
local GradientDrawable = luajava.bindClass("android.graphics.drawable.GradientDrawable")
local DisplayMetrics = luajava.bindClass("android.util.DisplayMetrics")

local root = FrameLayout(activity)

-- 1. 内容容器
local contentContainer = FrameLayout(activity)
local matchParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT)
contentContainer.setLayoutParams(matchParams)

local iv = ImageView(activity)
iv.setScaleType(ScaleType.CENTER_CROP)
iv.setLayoutParams(matchParams)
contentContainer.addView(iv)

local page1 = TextView(activity)
page1.setText("远程")
page1.setTextColor(0xFFFFFFFF)
page1.setTextSize(30)
page1.setGravity(Gravity.CENTER)
page1.setLayoutParams(matchParams)
contentContainer.addView(page1)

local page2 = TextView(activity)
page2.setText("第二页内容")
page2.setTextColor(0xFFFFFFFF)
page2.setTextSize(30)
page2.setGravity(Gravity.CENTER)
page2.setLayoutParams(matchParams)
page2.setVisibility(View.GONE)
contentContainer.addView(page2)

local loadFail = TextView(activity)
loadFail.setText("加载失败，请检查网络")
loadFail.setTextColor(0xFFFFFFFF)
loadFail.setBackgroundColor(0x88000000)
loadFail.setGravity(Gravity.CENTER)
loadFail.setTextSize(18)
loadFail.setLayoutParams(matchParams)
loadFail.setVisibility(View.GONE)
contentContainer.addView(loadFail)

root.addView(contentContainer)

-- 2. 底部悬浮卡片
local navWrapper = FrameLayout(activity)
local navParams = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT)
navParams.setMargins(20, 0, 20, 180)
navParams.gravity = Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL
navWrapper.setLayoutParams(navParams)

local baseRow = LinearLayout(activity)
baseRow.setOrientation(LinearLayout.HORIZONTAL)
baseRow.setLayoutParams(FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT))
local bgCard = GradientDrawable()
bgCard.setColor(0xCCF5F5F5)
bgCard.setCornerRadius(30)
baseRow.setBackgroundDrawable(bgCard)

local function loadIcon(url)
    local success, bmp = pcall(function()
        local conn = URL(url).openConnection()
        conn.setConnectTimeout(5000)
        conn.setReadTimeout(5000)
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/88.0.4324.181 Mobile Safari/537.36")
        conn.connect()
        return BitmapFactory.decodeStream(conn.getInputStream())
    end)
    if success and bmp then return bmp end
    return nil
end

local tabList = {}

local function createNavItem(url, pageView)
    local layout = LinearLayout(activity)
    layout.setOrientation(LinearLayout.VERTICAL)
    layout.setGravity(Gravity.CENTER)
    layout.setPadding(0, 15, 0, 15)
    local tabParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1)
    layout.setLayoutParams(tabParams)
    layout.setClickable(true)

    local iconView = ImageView(activity)
    local iconParams = LinearLayout.LayoutParams(150, 150)
    iconParams.setMargins(0, 0, 0, 25)
    iconView.setLayoutParams(iconParams)
    iconView.setScaleType(ScaleType.FIT_CENTER)
    
    local bmp = loadIcon(url)
    if bmp then
        iconView.setImageBitmap(bmp)
    else
        iconView.setImageResource(0)
    end

    layout.addView(iconView)
    baseRow.addView(layout)

    local tabObj = { layout = layout, page = pageView, icon = iconView }
    table.insert(tabList, tabObj)
    return tabObj
end

local homeTab = createNavItem("https://images.icon-icons.com/6274/PNG/96/346344_home-button-icon.png", page1)
local settingsTab = createNavItem("https://freeicon.com/cdn-cgi/image/width=512,quality=80,format=auto,fit=contain/https://storage.freeicon.com/free-icon-icon-aHyU76QjkuOD", page2)

navWrapper.addView(baseRow)

-- 3. 青色胶囊横条
local indicator = View(activity)
local indParams = FrameLayout.LayoutParams(150, 6)
indParams.gravity = Gravity.BOTTOM | Gravity.LEFT
indParams.setMargins(0, 0, 0, 30)
indicator.setLayoutParams(indParams)

local indBg = GradientDrawable()
indBg.setColor(0x00000000)
indBg.setCornerRadius(3)
indicator.setBackgroundDrawable(indBg)

navWrapper.addView(indicator)
root.addView(navWrapper)
activity.setContentView(root)

-- 4. 计算横条位置与动画
local dm = DisplayMetrics()
activity.getWindowManager().getDefaultDisplay().getMetrics(dm)

local function dpToPx(dp)
    return math.floor(dp * dm.density + 0.5)
end

local totalMargin = dpToPx(40)
local usableWidth = dm.widthPixels - totalMargin

local function selectTab(targetTab)
    for _, item in ipairs(tabList) do
        item.page.setVisibility(View.GONE)
    end
    targetTab.page.setVisibility(View.VISIBLE)

    local parentWidth = navWrapper.getWidth()
    if parentWidth <= 0 then parentWidth = usableWidth end
    local tabWidth = parentWidth / 2
    local halfIndicator = 75
    
    local targetX = 0
    if targetTab == homeTab then
        targetX = (tabWidth / 2) - halfIndicator
    elseif targetTab == settingsTab then
        targetX = (tabWidth + tabWidth / 2) - halfIndicator
    end

    indicator.setVisibility(View.VISIBLE)
    
    -- ★ 将黑色修改为好看的青蓝色（你可以自己换颜色代码）
    indBg.setColor(0xFF00BCD4) 
    indicator.setBackgroundDrawable(indBg)

    -- 终极动画修复：使用 View.animate()
    local success, err = pcall(function()
        local currentX = indicator.getTranslationX() or 0
        indicator.animate().translationX(targetX).setDuration(250).start()
    end)
    if not success then
        indicator.setTranslationX(targetX)
    end
end

homeTab.layout.setOnClickListener({ onClick = function() selectTab(homeTab) end })
settingsTab.layout.setOnClickListener({ onClick = function() selectTab(settingsTab) end })

-- 延迟启动首次定位
activity.getWindow().getDecorView().postDelayed({
    run = function()
        selectTab(homeTab)
    end
}, 300)

-- 5. 加载背景图
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
        loadFail.setVisibility(View.GONE)
    else
        iv.setVisibility(View.GONE)
        loadFail.setVisibility(View.VISIBLE)
    end
end

loadBg()
