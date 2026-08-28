require "import"
import "android.app.*"
import "android.os.*"
import "android.widget.*"
import "android.view.*"
import "android.graphics.drawable.GradientDrawable"
import "android.graphics.drawable.LayerDrawable"
import "android.util.TypedValue"
import "android.content.pm.PackageManager"
import "android.provider.Settings"
import "android.os.Build"
import "android.os.SystemClock"
import "android.app.ActivityManager"
import "android.os.Environment"
import "android.os.StatFs"
import "android.os.BatteryManager"
import "android.content.Intent"
import "android.content.IntentFilter"
import "android.net.ConnectivityManager"
import "android.net.NetworkInfo"
import "java.io.File"
import "java.io.BufferedReader"
import "java.io.InputStreamReader"
import "java.util.Calendar"
import "java.util.Locale"
import "java.util.TimeZone"
import "AndLua"

function dp(val)
  return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, val, activity.getResources().getDisplayMetrics())
end

function getBarHeight()
  local res = activity.getResources()
  local id = res.getIdentifier("status_bar_height", "dimen", "android")
  if id > 0 then return res.getDimensionPixelSize(id) end
  return dp(24)
end

function createCardShadowBg()
  local shadowDraw = GradientDrawable()
  shadowDraw.setShape(GradientDrawable.RECTANGLE)
  shadowDraw.setCornerRadius(28)
  shadowDraw.setColor(0x1A000000)

  local cardDraw = GradientDrawable()
  cardDraw.setShape(GradientDrawable.RECTANGLE)
  cardDraw.setCornerRadius(28)
  cardDraw.setColor(0xFFFCFCFA)

  local layerTable = {shadowDraw, cardDraw}
  local layer = LayerDrawable(layerTable)
  layer.setLayerInset(0, 2, 2, 2, 3)
  return layer
end

function execCommand(cmd)
  local ok, result = pcall(function()
    local process = Runtime.getRuntime().exec(cmd)
    local reader = BufferedReader(InputStreamReader(process.getInputStream()))
    local line = reader.readLine()
    reader.close()
    process.destroy()
    return line
  end)
  if ok then return result end
  return nil
end

function fileExists(path)
  local f = File(path)
  return f.exists()
end

function packageExists(pkg)
  local pm = activity.getPackageManager()
  local ok = pcall(function()
    pm.getPackageInfo(pkg, 0)
  end)
  if ok then return true end
  return false
end

function getProp(key)
  return execCommand("getprop " .. key) or ""
end

function scanMagiskApps()
  local pm = activity.getPackageManager()
  local apps = pm.getInstalledApplications(0)
  local found = {}

  for i = 0, apps.size() - 1 do
    local appInfo = apps.get(i)
    local pkgName = tostring(appInfo.packageName)
    local appName = tostring(pm.getApplicationLabel(appInfo))

    local lowerPkg = pkgName:lower()
    local lowerName = appName:lower()

    if lowerPkg:find("magisk") or lowerPkg:find("husky") or
       lowerName:find("magisk") or lowerName:find("面具") then
      table.insert(found, pkgName .. " (" .. appName .. ")")
    end
  end

  return found
end

function scanKernelSUApps()
  local pm = activity.getPackageManager()
  local apps = pm.getInstalledApplications(0)
  local found = {}

  for i = 0, apps.size() - 1 do
    local appInfo = apps.get(i)
    local pkgName = tostring(appInfo.packageName)
    local appName = tostring(pm.getApplicationLabel(appInfo))

    local lowerPkg = pkgName:lower()
    local lowerName = appName:lower()

    if lowerPkg:find("kernel") or lowerPkg:find("ksu") or lowerPkg:find("suki") or
       lowerName:find("kernel") or lowerName:find("ksu") or lowerName:find("suki") or
       lowerPkg:find("apatch") or lowerName:find("apatch") then
      table.insert(found, pkgName .. " (" .. appName .. ")")
    end
  end

  return found
end

function createCard(cardTitle, cardItems)
  local isExpand = false
  local contentLl
  local arrowTv
  local contentFullHeight = 0
  local animRunning = false
  local handler = Handler()
  local itemViews = {}
  local itemChecks = {}
  local cardLayerDrawable

  local function animateHeight(fromHeight, toHeight, duration, onEnd)
    local startTime = System.currentTimeMillis()
    local function update()
      if not animRunning then return end
      local elapsed = System.currentTimeMillis() - startTime
      local progress = math.min(elapsed / duration, 1.0)
      local t = progress
      t = t * t * (3 - 2 * t)
      local currentHeight = fromHeight + (toHeight - fromHeight) * t
      local lp = contentLl.getLayoutParams()
      lp.height = math.floor(currentHeight)
      contentLl.setLayoutParams(lp)
      if progress < 1.0 then
        handler.postDelayed(update, 16)
      else
        animRunning = false
        if onEnd then onEnd() end
      end
    end
    update()
  end

  local function expandAnim()
    if animRunning then return end
    animRunning = true
    if contentFullHeight <= 0 then
      contentLl.setVisibility(View.VISIBLE)
      local lp = contentLl.getLayoutParams()
      lp.height = ViewGroup.LayoutParams.WRAP_CONTENT
      contentLl.setLayoutParams(lp)
      contentLl.measure(
        View.MeasureSpec.makeMeasureSpec(contentLl.getWidth(), View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
      )
      contentFullHeight = contentLl.getMeasuredHeight()
    end
    contentLl.setVisibility(View.VISIBLE)
    arrowTv.setText("▲")
    animateHeight(0, contentFullHeight, 300, function() end)
  end

  local function collapseAnim()
    if animRunning then return end
    animRunning = true
    local startHeight = contentLl.getHeight()
    if startHeight <= 0 then startHeight = contentFullHeight end
    arrowTv.setText("▼")
    animateHeight(startHeight, 0, 300, function()
      contentLl.setVisibility(View.GONE)
    end)
  end

  cardLayerDrawable = createCardShadowBg()
  local cardLayoutTable = {
    LinearLayout,
    ["layout_width"] = "match_parent",
    ["layout_height"] = "wrap_content",
    ["orientation"] = "vertical",
    ["padding"] = "16dp",
    ["background"] = cardLayerDrawable,
    {
      LinearLayout,
      ["layout_width"] = "match_parent",
      ["layout_height"] = "wrap_content",
      ["gravity"] = "center_vertical",
      ["paddingVertical"] = "8dp",
      {
        Button,
        ["text"] = cardTitle,
        ["textSize"] = "15sp",
        ["textColor"] = "#1A1A1A",
        ["layout_weight"] = "1",
        ["layout_width"] = "0dp",
        ["background"] = "#00000000",
        ["gravity"] = "left|center_vertical",
        ["padding"] = "0dp"
      },
      {
        TextView,
        ["text"] = "▼",
        ["textSize"] = "13sp",
        ["textColor"] = "#666666"
      }
    },
    {
      LinearLayout,
      ["layout_width"] = "match_parent",
      ["layout_height"] = "0dp",
      ["orientation"] = "vertical",
      ["paddingTop"] = "10dp",
      ["visibility"] = View.GONE,
    }
  }

  local cardView = loadlayout(cardLayoutTable)
  local titleRow = cardView.getChildAt(0)
  local titleBtn = titleRow.getChildAt(0)
  arrowTv = titleRow.getChildAt(1)
  contentLl = cardView.getChildAt(1)

  for _, item in ipairs(cardItems) do
    local itemTv = TextView(activity)
    itemTv.setText("• " .. item.name)
    itemTv.setTextSize(14)
    itemTv.setTextColor(0xFF888888)
    itemTv.setPadding(dp(4), dp(4), dp(4), dp(4))
    itemTv.setLayoutParams(ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT))
    contentLl.addView(itemTv)
    table.insert(itemViews, itemTv)
    table.insert(itemChecks, item.check)
  end

  contentLl.post(luajava.createProxy("java.lang.Runnable", {
    run = function()
      contentLl.setVisibility(View.VISIBLE)
      local lp = contentLl.getLayoutParams()
      lp.height = ViewGroup.LayoutParams.WRAP_CONTENT
      contentLl.setLayoutParams(lp)
      contentLl.measure(
        View.MeasureSpec.makeMeasureSpec(cardView.getWidth(), View.MeasureSpec.EXACTLY),
        View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
      )
      contentFullHeight = contentLl.getMeasuredHeight()
      contentLl.setVisibility(View.GONE)
      lp.height = 0
      contentLl.setLayoutParams(lp)
    end
  }))

  titleBtn.setOnClickListener(luajava.createProxy("android.view.View$OnClickListener", {
    onClick = function(v)
      if animRunning then return end
      isExpand = not isExpand
      if isExpand then
        expandAnim()
      else
        collapseAnim()
      end
    end
  }))

  local function runDetection()
    local hasFound = false
    local hasSuspicious = false
    for i, tv in ipairs(itemViews) do
      local checkFunc = itemChecks[i]
      local status = false
      local value = nil
      if checkFunc then
        local ok, result1, result2 = pcall(checkFunc)
        if ok then
          status = result1
          value = result2
        end
      end

      local baseName = itemViews[i].getText():sub(3)
      if value and value ~= "" then
        tv.setText("• " .. baseName .. "：" .. value)
      end

      if status == "found" then
        tv.setTextColor(0xFFF44336)
        hasFound = true
      elseif status == "suspicious" then
        tv.setTextColor(0xFFFF9800)
        hasSuspicious = true
      else
        tv.setTextColor(0xFF4CAF50)
      end
    end

    local cardDraw = cardLayerDrawable.getDrawable(1)
    if hasFound then
      cardDraw.setColor(0xFFFFCDD2)
    elseif hasSuspicious then
      cardDraw.setColor(0xFFFFE0B2)
    else
      cardDraw.setColor(0xFFC8E6C9)
    end
  end

  cardView.setTag(runDetection)
  return cardView
end

local layoutTable = {
  LinearLayout,
  ["layout_width"] = "match_parent",
  ["layout_height"] = "match_parent",
  ["orientation"] = "vertical",
  ["padding"] = "14dp",
  ["background"] = "#E8F1FC",
  {
    TextView,
    ["layout_width"] = "match_parent",
    ["layout_height"] = getBarHeight(),
    ["background"] = "#00000000"
  },
  {
    ScrollView,
    ["layout_width"] = "match_parent",
    ["layout_height"] = "match_parent",
    {
      LinearLayout,
      ["layout_width"] = "match_parent",
      ["layout_height"] = "wrap_content",
      ["orientation"] = "vertical",
      ["padding"] = "4dp",
    }
  }
}

local rootView = loadlayout(layoutTable)
activity.setContentView(rootView)

local scrollView = rootView.getChildAt(1)
local container = scrollView.getChildAt(0)

-- ============ 原有检测函数 ============
function checkUsbDebug()
  local ok, result = pcall(function()
    return Settings.Global.getInt(activity.getContentResolver(), Settings.Global.ADB_ENABLED, 0) == 1
  end)
  if ok and result then return "suspicious" end
  return false
end

function checkWirelessDebug()
  local ok, result = pcall(function()
    return Settings.Global.getInt(activity.getContentResolver(), "adb_wifi_enabled", 0) == 1
  end)
  if ok and result then return "suspicious" end
  return false
end

function checkOemUnlock()
  local verified = getProp("ro.boot.verifiedbootstate")
  if verified == "orange" then return "found" end
  local locked = getProp("ro.boot.flash.locked")
  if locked == "0" then return "found" end
  return false
end

function checkBootloaderUnlock()
  local verified = getProp("ro.boot.verifiedbootstate")
  if verified == "orange" then return "found" end
  local locked = getProp("ro.boot.flash.locked")
  if locked == "0" then return "found" end
  return false
end

function checkPatchDate()
  local patch = getProp("ro.build.version.security_patch")
  if patch and patch ~= "" then
    local year = tonumber(string.sub(patch, 1, 4))
    local currentYear = Calendar.getInstance().get(Calendar.YEAR)
    local status = false
    if year and currentYear and (currentYear - year) >= 2 then
      status = "suspicious"
    end
    return status, patch
  end
  return false, "未知"
end

function checkSELinuxPermissive()
  return getProp("ro.build.selinux") == "0" and "found" or false
end

function checkDevOptions()
  local ok, result = pcall(function()
    return Settings.Global.getInt(activity.getContentResolver(), Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) == 1
  end)
  if ok and result then return "suspicious" end
  return false
end

function checkCpuArch()
  local arch = Build.CPU_ABI
  if arch and arch ~= "" then
    return false, arch
  end
  return false, "未知"
end

function checkKernelVersion()
  local kernelVersion = System.getProperty("os.version")
  if kernelVersion == nil or kernelVersion == "" then
    kernelVersion = "未知"
  end
  return false, kernelVersion
end

function checkAndroidVersion()
  local androidVersion = Build.VERSION.RELEASE
  if androidVersion == nil or androidVersion == "" then
    androidVersion = "未知"
  end
  return false, androidVersion
end

function checkSystemUptime()
  local ok, uptimeMs = pcall(function()
    return SystemClock.uptimeMillis()
  end)
  if not ok or uptimeMs == nil then
    return false, "未知"
  end

  local totalSeconds = math.floor(uptimeMs / 1000)
  local days = math.floor(totalSeconds / 86400)
  local hours = math.floor((totalSeconds % 86400) / 3600)
  local minutes = math.floor((totalSeconds % 3600) / 60)
  local seconds = totalSeconds % 60

  local text
  if days > 0 then
    text = string.format("%d天%d小时%d分", days, hours, minutes)
  elseif hours > 0 then
    text = string.format("%d小时%d分", hours, minutes)
  elseif minutes > 0 then
    text = string.format("%d分%d秒", minutes, seconds)
  else
    text = string.format("%d秒", seconds)
  end

  return false, text
end

function checkVirtualMachine()
  local hw = Build.HARDWARE
  local prod = Build.PRODUCT
  local model = Build.MODEL
  local finger = Build.FINGERPRINT

  if hw and (hw:lower():find("goldfish") or hw:lower():find("ranchu")) then return "found", "硬件特征: " .. hw end
  if prod and (prod:lower():find("sdk") or prod:lower():find("emulator")) then return "found", "产品: " .. prod end
  if model and (model:lower():find("emulator") or model:lower():find("android sdk")) then return "found", "型号: " .. model end
  if finger and (finger:lower():find("generic") or finger:lower():find("emulator") or finger:lower():find("vbox")) then return "found", "指纹: " .. finger end

  local vmFiles = {
    "/dev/qemu_pipe",
    "/dev/goldfish_pipe",
    "/dev/vboxguest",
    "/dev/vmci",
    "/system/lib/libc_malloc_debug_qemu.so",
    "/system/bin/qemu-props",
    "/system/bin/nox",
    "/system/bin/ttVM",
    "/system/etc/init.vbox.sh"
  }
  for _, path in ipairs(vmFiles) do
    if fileExists(path) then
      return "found", path
    end
  end

  local qemuProps = {
    "ro.kernel.qemu",
    "ro.boot.qemu",
    "init.svc.qemu_props"
  }
  for _, prop in ipairs(qemuProps) do
    local val = getProp(prop)
    if val and val ~= "" then
      local lowerVal = val:lower()
      if lowerVal:find("qemu") or lowerVal:find("goldfish") or lowerVal:find("ranchu") or lowerVal:find("vbox") or lowerVal:find("emulator") then
        return "found", prop .. " = " .. val
      end
    end
  end

  local cpuInfo = execCommand("cat /proc/cpuinfo")
  if cpuInfo and (cpuInfo:lower():find("qemu") or cpuInfo:lower():find("goldfish") or cpuInfo:lower():find("vbox")) then
    return "found", "cpuinfo 含虚拟机特征"
  end

  return false
end

-- ============ 新增基础信息检测函数（16项） ============
function checkDeviceBrand()
  return false, Build.BRAND or "未知"
end

function checkDeviceModel()
  return false, Build.MODEL or "未知"
end

function checkManufacturer()
  return false, Build.MANUFACTURER or "未知"
end

function checkHardwarePlatform()
  local hw = getProp("ro.board.platform")
  if hw and hw ~= "" then
    return false, hw
  end
  return false, Build.HARDWARE or "未知"
end

function checkScreenResolution()
  local dm = activity.getResources().getDisplayMetrics()
  return false, dm.widthPixels .. "x" .. dm.heightPixels
end

function checkScreenDensity()
  local dm = activity.getResources().getDisplayMetrics()
  return false, dm.densityDpi .. "dpi"
end

function checkTotalMemory()
  local am = activity.getSystemService(Activity.ACTIVITY_SERVICE)
  local memInfo = ActivityManager.MemoryInfo()
  am.getMemoryInfo(memInfo)
  return false, string.format("%.2f GB", memInfo.totalMem / 1024 / 1024 / 1024)
end

function checkAvailableStorage()
  local stat = StatFs(Environment.getDataDirectory().getPath())
  local totalBytes = stat.getTotalBytes()
  return false, string.format("%.2f GB", totalBytes / 1024 / 1024 / 1024)
end

function checkBatteryStatus()
  local batteryIntent = activity.registerReceiver(nil, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
  if batteryIntent ~= nil then
    local level = batteryIntent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1)
    local scale = batteryIntent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
    if level >= 0 and scale > 0 then
      return false, string.format("%d%%", math.floor(level * 100 / scale))
    end
  end
  return false, "未知"
end

function checkNetworkType()
  local cm = activity.getSystemService(Activity.CONNECTIVITY_SERVICE)
  local info = cm.getActiveNetworkInfo()
  if info ~= nil and info.isConnected() then
    return false, info.getTypeName()
  end
  return false, "无网络"
end

function checkSystemLanguage()
  return false, Locale.getDefault().getLanguage() .. "-" .. Locale.getDefault().getCountry()
end

function checkTimeZone()
  return false, TimeZone.getDefault().getID()
end

function checkBluetoothAddress()
  local addr = Settings.Secure.getString(activity.getContentResolver(), "bluetooth_address")
  if addr == nil or addr == "" then
    return false, "未知"
  end
  if addr == "00:00:00:00:00:00" or addr:lower():find("00:00:00:00") then
    return "suspicious", addr
  end
  return false, addr
end

function checkWifiMacAddress()
  local addr = Settings.Secure.getString(activity.getContentResolver(), "wifi_mac")
  if addr == nil or addr == "" then
    return false, "未知"
  end
  if addr == "02:00:00:00:00:00" or addr == "00:00:00:00:00:00" then
    return "suspicious", addr
  end
  return false, addr
end

function checkBasebandVersion()
  local baseband = Build.getRadioVersion()
  if baseband == nil or baseband == "" then
    return false, "未知"
  end
  return false, baseband
end

function checkBuildID()
  return false, Build.ID or "未知"
end

-- ============ 原有其他检测函数 ============
function checkSuCommand()
  local result = execCommand("su -c id")
  if result and result:find("uid=0") then return "found" end
  return false
end

function checkSuFile()
  return (fileExists("/system/xbin/su") or fileExists("/system/bin/su") or fileExists("/sbin/su")) and "found" or false
end

function checkUidZero()
  local result = execCommand("id")
  if result and result:find("uid=0") then return "found" end
  return false
end

function checkPathSu()
  local path = os.getenv("PATH")
  if path and path:lower():find("su") then return "found" end
  return false
end

function checkSuperuserApk()
  return fileExists("/system/app/Superuser.apk") and "found" or false
end

function checkSuPath(path)
  return fileExists(path) and "found" or false
end

function checkBusybox()
  if fileExists("/system/xbin/busybox") or fileExists("/system/bin/busybox") or fileExists("/sbin/busybox") then
    return "suspicious"
  end
  return false
end

function checkMagiskManager()
  return packageExists("com.topjohnwu.magisk") and "found" or false
end

function checkAlphaMagisk()
  local knownPackages = {
    "io.github.huskydg.magisk.alpha",
    "io.github.huskydg.magisk.alpha.canary"
  }
  for _, pkg in ipairs(knownPackages) do
    if packageExists(pkg) then
      return "found", pkg
    end
  end

  local apps = scanMagiskApps()
  for _, info in ipairs(apps) do
    local lowerInfo = info:lower()
    if lowerInfo:find("alpha") or lowerInfo:find("阿尔法") then
      return "found", info
    end
  end
  return false
end

function checkDeltaMagisk()
  local knownPackages = {
    "io.github.huskydg.magisk.delta",
    "io.github.huskydg.magisk.hidden",
    "com.topjohnwu.magisk.delta"
  }
  for _, pkg in ipairs(knownPackages) do
    if packageExists(pkg) then
      return "found", pkg
    end
  end

  local apps = scanMagiskApps()
  for _, info in ipairs(apps) do
    local lowerInfo = info:lower()
    if lowerInfo:find("delta") or lowerInfo:find("德尔塔") then
      return "found", info
    end
  end

  for _, info in ipairs(apps) do
    local lowerInfo = info:lower()
    local isOfficial = lowerInfo:find("com.topjohnwu.magisk") ~= nil
    local isAlpha = lowerInfo:find("alpha") ~= nil or lowerInfo:find("阿尔法") ~= nil
    if not isOfficial and not isAlpha then
      return "found", info
    end
  end

  return false
end

function checkMagiskBinary()
  return fileExists("/data/adb/magisk") and "found" or false
end

function checkMagiskModules()
  return fileExists("/data/adb/modules") and "found" or false
end

function checkMagiskMount()
  return (fileExists("/sbin/.magisk") or fileExists("/dev/magisk")) and "found" or false
end

function checkMagiskDb()
  return fileExists("/data/adb/magisk.db") and "found" or false
end

function checkAdbDir()
  return fileExists("/data/adb") and "suspicious" or false
end

function checkKernelSUManager()
  return packageExists("me.weishu.kernelsu") and "found" or false
end

function checkKernelModule()
  return fileExists("/sys/module/kernelsu") and "found" or false
end

function checkKsuDir()
  return fileExists("/data/adb/ksu") and "found" or false
end

function checkKsuDev()
  return fileExists("/dev/ksu") and "found" or false
end

function checkSukiSU()
  local knownPackages = {
    "com.suki.sukisu",
    "com.suki.sukisu.ultra",
    "com.sukisu.ultra",
    "com.suki.kernelsu",
    "com.sukisu.manager"
  }
  for _, pkg in ipairs(knownPackages) do
    if packageExists(pkg) then
      return "found", pkg
    end
  end

  local apps = scanKernelSUApps()
  for _, info in ipairs(apps) do
    local lowerInfo = info:lower()
    if lowerInfo:find("sukisu") or lowerInfo:find("suki su") then
      return "found", info
    end
  end
  return false
end

function checkAPatch()
  local knownPackages = {
    "me.bmax.apatch",
    "com.apatch",
    "com.apatch.manager",
    "me.bmax.apatch.manager",
    "com.bmax.apatch"
  }
  for _, pkg in ipairs(knownPackages) do
    if packageExists(pkg) then
      return "found", pkg
    end
  end

  local apps = scanKernelSUApps()
  for _, info in ipairs(apps) do
    local lowerInfo = info:lower()
    if lowerInfo:find("apatch") then
      return "found", info
    end
  end

  if fileExists("/sys/module/apatch") then return "found", "/sys/module/apatch" end
  if fileExists("/data/adb/apatch") then return "found", "/data/adb/apatch" end
  if fileExists("/dev/apatch") then return "found", "/dev/apatch" end
  return false
end

function checkSystemWritable()
  local mounts = execCommand("cat /proc/mounts")
  if mounts then
    for line in mounts:gmatch("[^\r\n]+") do
      if line:find("/system") and line:find(" rw,") then return "found" end
    end
  end
  return false
end

function checkVendorWritable()
  local mounts = execCommand("cat /proc/mounts")
  if mounts then
    for line in mounts:gmatch("[^\r\n]+") do
      if line:find("/vendor") and line:find(" rw,") then return "suspicious" end
    end
  end
  return false
end

function checkMagiskMountPoint()
  return fileExists("/dev/magisk") and "found" or false
end

function checkXposedInstaller()
  return packageExists("de.robv.android.xposed.installer") and "found" or false
end

function checkLSPosed()
  return packageExists("org.lsposed.manager") and "found" or false
end

function checkEdXposed()
  return packageExists("org.meowcat.edxposed.manager") and "found" or false
end

function checkHiddenAppList()
  return packageExists("com.tsng.hidemyapplist") and "suspicious" or false
end

function checkDebuggable()
  return getProp("ro.debuggable") == "1" and "suspicious" or false
end

function checkSecure()
  return getProp("ro.secure") == "0" and "found" or false
end

function checkBuildTags()
  local tags = Build.TAGS
  if tags and tags:lower():find("test-keys") then return "found" end
  return false
end

function checkBuildType()
  return Build.TYPE:lower() == "eng" and "found" or false
end

function checkOemUnlockAllowed()
  return getProp("sys.oem_unlock_allowed") == "1" and "suspicious" or false
end

function checkNativeBridge()
  return getProp("ro.dalvik.vm.native.bridge") ~= "" and "suspicious" or false
end

function checkEmulatorHardware()
  local hw = Build.HARDWARE
  if hw and (hw:lower():find("goldfish") or hw:lower():find("ranchu")) then return "found" end
  return false
end

function checkQemuPipe()
  return fileExists("/dev/qemu_pipe") and "found" or false
end

function checkEmulatorRenderer()
  local hw = Build.HARDWARE
  if hw and hw:lower():find("emulator") then return "found" end
  return false
end

function checkSystemWritableFile()
  return checkSystemWritable()
end

function checkSdcardSu()
  return fileExists("/sdcard/su") and "found" or false
end

function checkCacheSu()
  return fileExists("/cache/su") and "found" or false
end

-- ============ 分类定义 ============
local detectionCategories = {
  {
    title = "系统基础信息",
    items = {
      { name = "设备品牌", check = checkDeviceBrand },
      { name = "设备型号", check = checkDeviceModel },
      { name = "制造商", check = checkManufacturer },
      { name = "硬件平台", check = checkHardwarePlatform },
      { name = "屏幕分辨率", check = checkScreenResolution },
      { name = "屏幕密度", check = checkScreenDensity },
      { name = "运行内存", check = checkTotalMemory },
      { name = "存储空间", check = checkAvailableStorage },
      { name = "电池状态", check = checkBatteryStatus },
      { name = "网络类型", check = checkNetworkType },
      { name = "系统语言", check = checkSystemLanguage },
      { name = "时区", check = checkTimeZone },
      { name = "蓝牙地址", check = checkBluetoothAddress },
      { name = "Wi-Fi MAC", check = checkWifiMacAddress },
      { name = "基带版本", check = checkBasebandVersion },
      { name = "构建ID", check = checkBuildID },
      { name = "USB调试", check = checkUsbDebug },
      { name = "无线调试", check = checkWirelessDebug },
      { name = "OEM解锁", check = checkOemUnlock },
      { name = "BL解锁", check = checkBootloaderUnlock },
      { name = "补丁更新日期", check = checkPatchDate },
      { name = "SELinux 状态", check = checkSELinuxPermissive },
      { name = "开发者选项", check = checkDevOptions },
      { name = "CPU架构", check = checkCpuArch },
      { name = "系统内核", check = checkKernelVersion },
      { name = "安卓版本", check = checkAndroidVersion },
      { name = "系统运行时间", check = checkSystemUptime },
      { name = "虚拟机镜像", check = checkVirtualMachine },
      { name = "内核命令行", check = function() return false end },
      { name = "Boot 镜像签名", check = function() return false end }
    }
  },
  {
    title = "Root权限检测",
    items = {
      { name = "su 命令执行", check = checkSuCommand },
      { name = "su 可执行文件", check = checkSuFile },
      { name = "uid=0 可用", check = checkUidZero },
      { name = "环境变量 PATH 包含 su", check = checkPathSu },
      { name = "/system/app/Superuser.apk", check = checkSuperuserApk },
      { name = "/data/app 中的 Root 应用", check = function() return false end },
      { name = "ro.dalvik.vm.native.bridge", check = checkNativeBridge },
      { name = "SuperSU 包名", check = function() return packageExists("eu.chainfire.supersu") and "found" or false end },
      { name = "运行中进程 root 特征", check = function() return false end }
    }
  },
  {
    title = "SU文件检测",
    items = {
      { name = "/system/xbin/su", check = function() return checkSuPath("/system/xbin/su") end },
      { name = "/system/bin/su", check = function() return checkSuPath("/system/bin/su") end },
      { name = "/sbin/su", check = function() return checkSuPath("/sbin/su") end },
      { name = "/data/local/su", check = function() return checkSuPath("/data/local/su") end },
      { name = "/data/local/bin/su", check = function() return checkSuPath("/data/local/bin/su") end },
      { name = "/data/local/xbin/su", check = function() return checkSuPath("/data/local/xbin/su") end },
      { name = "/system/sd/xbin/su", check = function() return checkSuPath("/system/sd/xbin/su") end },
      { name = "/vendor/bin/su", check = function() return checkSuPath("/vendor/bin/su") end },
      { name = "/system/bin/failsafe/su", check = function() return checkSuPath("/system/bin/failsafe/su") end },
      { name = "/su/bin/su", check = function() return checkSuPath("/su/bin/su") end },
      { name = "busybox", check = checkBusybox },
      { name = "/apex/com.android.runtime/bin/su", check = function() return checkSuPath("/apex/com.android.runtime/bin/su") end }
    }
  },
  {
    title = "Magisk检测",
    items = {
      { name = "Magisk 管理器", check = checkMagiskManager },
      { name = "阿尔法面具", check = checkAlphaMagisk },
      { name = "德尔塔面具", check = checkDeltaMagisk },
      { name = "Magisk 二进制", check = checkMagiskBinary },
      { name = "Magisk 模块目录", check = checkMagiskModules },
      { name = "Magisk 挂载点", check = checkMagiskMount },
      { name = "/proc/self/mounts 中的 magisk", check = function() return false end },
      { name = "/data/adb/magisk.db", check = checkMagiskDb },
      { name = "boot 镜像已修补", check = function() return false end },
      { name = "magiskinit 进程", check = function() return false end },
      { name = "/cache/.disable_magisk", check = function() return fileExists("/cache/.disable_magisk") and "found" or false end },
      { name = "/data/adb 目录", check = checkAdbDir }
    }
  },
  {
    title = "KernelSU检测",
    items = {
      { name = "KernelSU 管理器", check = checkKernelSUManager },
      { name = "内核模块 ksu", check = checkKernelModule },
      { name = "/data/adb/ksu 目录", check = checkKsuDir },
      { name = "内核命令行包含 ksu", check = function() return false end },
      { name = "/proc/version 特征", check = function() return false end },
      { name = "SuperUser 相关挂载", check = function() return false end },
      { name = "/system/etc/init/ksud", check = function() return fileExists("/system/etc/init/ksud") and "suspicious" or false end },
      { name = "/proc/modules 中的 ksu", check = function() return false end },
      { name = "/sys/module/kernelsu", check = checkKernelModule },
      { name = "/dev/ksu 设备节点", check = checkKsuDev },
      { name = "SukiSU Ultra", check = checkSukiSU },
      { name = "APatch", check = checkAPatch }
    }
  },
  {
    title = "挂载检测",
    items = {
      { name = "/system 可写", check = checkSystemWritable },
      { name = "/vendor 可写", check = checkVendorWritable },
      { name = "/data 可写", check = function() return false end },
      { name = "可疑 tmpfs 挂载", check = function() return false end },
      { name = "debugfs 挂载", check = function() return false end },
      { name = "su 相关挂载", check = function() return false end },
      { name = "overlay 文件系统", check = function() return false end },
      { name = "/sbin 挂载异常", check = function() return false end },
      { name = "/proc/self/mountinfo 异常路径", check = function() return false end },
      { name = "/dev/magisk 挂载点", check = checkMagiskMountPoint },
      { name = "/dev/ksu 设备节点", check = checkKsuDev }
    }
  },
  {
    title = "Xposed框架检测",
    items = {
      { name = "XposedBridge.jar", check = function() return false end },
      { name = "Xposed Installer", check = checkXposedInstaller },
      { name = "EdXposed 管理器", check = checkEdXposed },
      { name = "LSPosed", check = checkLSPosed },
      { name = "类加载器 Xposed", check = function() return false end },
      { name = "/data/data/de.robv.android.xposed.installer", check = function() return fileExists("/data/data/de.robv.android.xposed.installer") and "found" or false end },
      { name = "LSPosed 模块列表", check = function() return false end },
      { name = "隐藏应用列表", check = checkHiddenAppList },
      { name = "其他 Xposed 模块", check = function() return false end },
      { name = "/data/misc/edxp", check = function() return fileExists("/data/misc/edxp") and "found" or false end },
      { name = "应用权限 Xposed 相关", check = function() return false end }
    }
  },
  {
    title = "系统属性检测",
    items = {
      { name = "ro.debuggable", check = checkDebuggable },
      { name = "ro.secure", check = checkSecure },
      { name = "ro.build.tags", check = checkBuildTags },
      { name = "ro.build.type", check = checkBuildType },
      { name = "ro.bootmode", check = function() return false end },
      { name = "ro.hardware", check = function() return false end },
      { name = "ro.product.name", check = function() return false end },
      { name = "sys.oem_unlock_allowed", check = checkOemUnlockAllowed },
      { name = "ro.build.selinux", check = checkSELinuxPermissive },
      { name = "ro.apex.updatable", check = function() return false end },
      { name = "ro.crypto.state", check = function() return false end },
      { name = "ro.dalvik.vm.native.bridge", check = checkNativeBridge }
    }
  },
  {
    title = "模拟器检测",
    items = {
      { name = "硬件特征 Goldfish/Ranchu", check = checkEmulatorHardware },
      { name = "传感器存在性", check = function() return false end },
      { name = "IMEI/MEID 有效性", check = function() return false end },
      { name = "蓝牙地址", check = function() return false end },
      { name = "电池状态", check = function() return false end },
      { name = "内核消息 qemu", check = function() return false end },
      { name = "图形渲染器 Emulator", check = checkEmulatorRenderer },
      { name = "设备指纹", check = function() return false end },
      { name = "CPU 架构", check = checkCpuArch },
      { name = "/dev/qemu_pipe", check = checkQemuPipe },
      { name = "/proc/cpuinfo emulator 特征", check = function() return false end }
    }
  },
  {
    title = "文件系统检测",
    items = {
      { name = "/system/app/Superuser.apk", check = checkSuperuserApk },
      { name = "/system 可写", check = checkSystemWritableFile },
      { name = "init.rc 被修改", check = function() return false end },
      { name = "/data/local/tmp 可执行文件", check = function() return false end },
      { name = "/sdcard/su", check = checkSdcardSu },
      { name = "/cache/su", check = checkCacheSu },
      { name = "/data/adb 目录", check = checkAdbDir },
      { name = "/data/local/tmp 可疑文件", check = function() return false end },
      { name = "CapEff 含 CAP_SYS_ADMIN", check = function() return false end },
      { name = "uid_map 含 0 映射", check = function() return false end }
    }
  }
}

local cards = {}

for i, category in ipairs(detectionCategories) do
  local card = createCard(category.title, category.items)
  card.setAlpha(0)
  card.setTranslationY(dp(30))
  container.addView(card)
  table.insert(cards, card)

  if i < #detectionCategories then
    local spacer = TextView(activity)
    spacer.setLayoutParams(ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, dp(12)))
    spacer.setBackgroundColor(0x00000000)
    container.addView(spacer)
  end
end

rootView.post(luajava.createProxy("java.lang.Runnable", {
  run = function()
    for i, card in ipairs(cards) do
      card.animate()
        .alpha(1)
        .translationY(0)
        .setDuration(400)
        .setStartDelay((i - 1) * 100)
        .start()
    end

    local totalAnimTime = (#cards - 1) * 100 + 400
    Handler().postDelayed(luajava.createProxy("java.lang.Runnable", {
      run = function()
        local index = 1
        local function runNext()
          if index <= #cards then
            local card = cards[index]
            local detectFunc = card.getTag()
            if detectFunc then
              detectFunc()
            end
            index = index + 1
            Handler().postDelayed(luajava.createProxy("java.lang.Runnable", {
              run = runNext
            }), 200)
          end
        end
        runNext()
      end
    }), totalAnimTime + 500)
  end
}))

沉浸状态栏()
local window = activity.getWindow()
local decor = window.getDecorView()
decor.setSystemUiVisibility(View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR)
