local packageName = activity.getPackageName()
if packageName ~= "com.karen" then
    local builder = AlertDialog.Builder(activity)
    builder.setTitle("验败")
    builder.setMessage("当前应用包名不正确，即将退出。")
    builder.setCancelable(false)
    builder.setPositiveButton("确定", {onClick = function()
        activity.finish()
        System.exit(0)
        Process.killProcess(Process.myPid())
    end})
    builder.show()
    return
end
