require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.Color"
import "android.graphics.Typeface"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.ColorDrawable"
import "android.os.Build"
import "android.view.animation.OvershootInterpolator"
import "android.view.animation.DecelerateInterpolator"
import "AndLua"
local page1 = require "q1"
local page2 = require "q2"
local page3 = require "q3"

activity.setTheme(android.R.style.Theme_Black_NoTitleBar)
if activity.getActionBar() then activity.getActionBar().hide() end
local window = activity.getWindow()
if Build.VERSION.SDK_INT >= 21 then
  window.setStatusBarColor(Color.TRANSPARENT)
  window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_STABLE)
end
window.getDecorView().setBackgroundColor(Color.BLACK)

local density = activity.getResources().getDisplayMetrics().density
local screenWidth = activity.getResources().getDisplayMetrics().widthPixels

local sp = activity.getSharedPreferences("login", 0)
local isLogin = sp.getString("status", "false") == "true"

local function showForceDialog()
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
  titleTv.setText("未知错误")
  titleTv.setTextColor(Color.parseColor("#FFD700"))
  titleTv.setTextSize(24)
  titleTv.setTypeface(Typeface.DEFAULT_BOLD)
  titleTv.setGravity(Gravity.CENTER)
  dLayout.addView(titleTv)
  local msgTv = TextView(activity)
  msgTv.setText("服务器返回时间戳校验失败！请重启APP")
  msgTv.setTextColor(Color.WHITE)
  msgTv.setTextSize(16)
  msgTv.setGravity(Gravity.CENTER)
  msgTv.setPadding(0, math.floor(20 * density), 0, math.floor(20 * density))
  dLayout.addView(msgTv)
  local btn = TextView(activity)
  btn.setText("退出")
  btn.setTextColor(Color.BLACK)
  btn.setTextSize(18)
  btn.setGravity(Gravity.CENTER)
  local btnBg = GradientDrawable()
  btnBg.setColor(Color.parseColor("#FFD700"))
  btnBg.setCornerRadius(math.floor(15 * density))
  btn.setBackground(btnBg)
  local btnLp = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, math.floor(50 * density))
  btnLp.topMargin = math.floor(20 * density)
  btn.setLayoutParams(btnLp)
  btn.setOnClickListener({
    onClick = function()
      dialog.dismiss()
      activity.finish()
    end
  })
  dLayout.addView(btn)
  dialog.setContentView(dLayout)
  dialog.getWindow().setBackgroundDrawable(ColorDrawable(Color.TRANSPARENT))
  dialog.show()
end

if isLogin ~= true then
  showForceDialog()
 else
  local rootLayout = FrameLayout(activity)
  rootLayout.setBackgroundColor(Color.BLACK)
  local contentContainer = FrameLayout(activity)
  contentContainer.setLayoutParams(FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
  rootLayout.addView(contentContainer)

  local navBar = FrameLayout(activity)
  -- 日落极光微光导航栏
  local navBg = GradientDrawable()
  navBg.setOrientation(GradientDrawable.Orientation.LEFT_RIGHT)
  navBg.setColors({
    Color.parseColor("#4DFF7B5C"), -- 暖橙 30%透明
    Color.parseColor("#4DFF5E7A"), -- 珊瑚粉 30%透明
    Color.parseColor("#4DC77DFF"), -- 淡紫 30%透明
  })
  navBg.setCornerRadius(math.floor(30 * density))
  navBar.setBackground(navBg)
  local navLp = FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, math.floor(60 * density))
  navLp.gravity = Gravity.BOTTOM
  navLp.leftMargin = math.floor(15 * density)
  navLp.rightMargin = math.floor(15 * density)
  navLp.bottomMargin = math.floor(15 * density)
  navBar.setLayoutParams(navLp)
  if Build.VERSION.SDK_INT >= 21 then
    navBar.setElevation(math.floor(12 * density))
  end

  local tabWidth = (screenWidth - math.floor(30 * density)) / 3
  local indicatorWidth = math.floor(tabWidth - 40 * density)
  local indicatorHeight = math.floor(36 * density)
  local indicatorCenterOffset = math.floor((tabWidth - indicatorWidth) / 2)
  local navLeftMargin = math.floor(15 * density)

  local pages = {
    page1(activity, density),
    page2(activity, density),
    page3(activity, density)
  }

  local currentIndex = 0
  local function switchPage(index)
    if index == currentIndex then return end
    local newPage = pages[index]
    newPage.setAlpha(0)
    contentContainer.removeAllViews()
    contentContainer.addView(newPage)
    newPage.animate().alpha(1).setDuration(200).start()
    currentIndex = index
  end

  -- 日落极光渐变胶囊指示器
  local indicator = View(activity)
  local indBg = GradientDrawable()
  indBg.setOrientation(GradientDrawable.Orientation.LEFT_RIGHT)
  indBg.setColors({
    Color.parseColor("#FF7B5C"), -- 暖橙
    Color.parseColor("#FF5E7A"), -- 珊瑚粉
    Color.parseColor("#C77DFF"), -- 淡紫
  })
  indBg.setCornerRadius(math.floor(18 * density))
  indBg.setStroke(math.floor(1.5 * density), Color.parseColor("#33FFFFFF"))
  indicator.setBackground(indBg)
  if Build.VERSION.SDK_INT >= 21 then
    indicator.setElevation(math.floor(6 * density))
  end
  local indLp = FrameLayout.LayoutParams(indicatorWidth, indicatorHeight)
  indLp.gravity = Gravity.START | Gravity.CENTER_VERTICAL
  indLp.leftMargin = 0
  indicator.setLayoutParams(indLp)
  navBar.addView(indicator)

  local tabContainer = LinearLayout(activity)
  tabContainer.setOrientation(LinearLayout.HORIZONTAL)
  tabContainer.setGravity(Gravity.CENTER)
  tabContainer.setLayoutParams(FrameLayout.LayoutParams(FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT))
  if Build.VERSION.SDK_INT >= 21 then
    tabContainer.setElevation(math.floor(8 * density))
  end
  navBar.addView(tabContainer)

  local tabTitles = {"主页", "终端", "关于"}
  local tabViews = {}
  local selectedColor = Color.WHITE
  local normalColor = Color.parseColor("#666666")

  local currentHighlightIndex = 1

  local function getNearestIndex(centerX)
    local bestIndex = 1
    local minDist = 1e9
    for i = 1, #tabTitles do
      local tabCenter = (i - 0.5) * tabWidth
      local dist = math.abs(centerX - tabCenter)
      if dist < minDist then
        minDist = dist
        bestIndex = i
      end
    end
    return bestIndex
  end

  local function updateColors(tempIndex)
    if tempIndex ~= currentHighlightIndex then
      for j, tv in ipairs(tabViews) do
        if j == tempIndex then
          tv.setTextColor(selectedColor)
         else
          tv.setTextColor(normalColor)
        end
      end
      currentHighlightIndex = tempIndex
    end
  end

  local function switchToTab(index)
    updateColors(index)
    switchPage(index)
    local targetX = (index - 1) * tabWidth + indicatorCenterOffset
    indicator.animate().translationX(targetX).setDuration(250).setInterpolator(DecelerateInterpolator()).start()
  end

  for i, title in ipairs(tabTitles) do
    local tab = TextView(activity)
    tab.setText(title)
    tab.setTextSize(16)
    tab.setGravity(Gravity.CENTER)
    tab.setIncludeFontPadding(false)
    tab.setTextColor(normalColor)
    tab.setTypeface(Typeface.DEFAULT_BOLD)
    tab.setShadowLayer(1, 0, 1, Color.parseColor("#55000000"))
    local tabLp = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1)
    tab.setLayoutParams(tabLp)
    table.insert(tabViews, tab)
    tabContainer.addView(tab)
  end

  local downX = 0
  local downTranslationX = 0
  local isDragging = false
  local touchOnIndicator = false
  local touchSlop = math.floor(10 * density)

  local function isTouchOnIndicator(rawX)
    local indLeft = navLeftMargin + indicator.getTranslationX()
    local indRight = indLeft + indicatorWidth + math.floor(20 * density)
    return rawX >= indLeft and rawX <= indRight
  end

  tabContainer.onTouch = function(v, event)
    local action = event.getAction()
    if action == MotionEvent.ACTION_DOWN then
      downX = event.getRawX()
      downTranslationX = indicator.getTranslationX()
      isDragging = false
      touchOnIndicator = isTouchOnIndicator(downX)
      if touchOnIndicator then
        indicator.animate().scaleX(1.50).scaleY(1.50).setDuration(200).setInterpolator(OvershootInterpolator()).start()
      end
      return true
     elseif action == MotionEvent.ACTION_MOVE then
      local deltaX = event.getRawX() - downX
      if math.abs(deltaX) > touchSlop and touchOnIndicator then
        isDragging = true
      end
      if isDragging then
        local newX = downTranslationX + deltaX
        local minX = indicatorCenterOffset
        local maxX = (#tabTitles - 1) * tabWidth + indicatorCenterOffset
        if newX < minX then newX = minX end
        if newX > maxX then newX = maxX end
        indicator.setTranslationX(newX)
        local centerX = newX + indicatorWidth / 2
        local tempIndex = getNearestIndex(centerX)
        updateColors(tempIndex)
        switchPage(tempIndex)
      end
      return true
     elseif action == MotionEvent.ACTION_UP or action == MotionEvent.ACTION_CANCEL then
      indicator.animate().scaleX(1).scaleY(1).setDuration(400).setInterpolator(OvershootInterpolator()).start()
      if isDragging then
        local centerX = indicator.getTranslationX() + indicatorWidth / 2
        local targetIndex = getNearestIndex(centerX)
        switchToTab(targetIndex)
       else
        local targetIndex = math.floor((downX - navLeftMargin) / tabWidth) + 1
        if targetIndex < 1 then targetIndex = 1 end
        if targetIndex > #tabTitles then targetIndex = #tabTitles end
        switchToTab(targetIndex)
      end
      return true
    end
    return false
  end

  rootLayout.addView(navBar)

  switchPage(1)
  tabViews[1].setTextColor(selectedColor)
  indicator.setTranslationX(indicatorCenterOffset)
  currentHighlightIndex = 1

  activity.setContentView(rootLayout)
  
end
