local packageName = activity.getPackageName()
if packageName ~= "com.baoming" then
    local builder = AlertDialog.Builder(activity)
    builder.setTitle("验证失败")
    builder.setMessage("当前应用包名不正确，即将退出。")
    builder.setCancelable(false)
    builder.setPositiveButton("退出", {onClick = function()
        activity.finish()
        System.exit(0)
        Process.killProcess(Process.myPid())
    end})
    builder.show()
    return
end
