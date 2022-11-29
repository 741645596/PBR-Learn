

using System.Collections.Generic;

public abstract class AssetInfoBase
{
    // unity内的相对路径
    public string assetPath;

    // 文件大小
    public long filesize;

    public abstract bool IsError();

    public abstract string GetErrorDes();

    public abstract bool CanFix();

    public abstract void Fix();
}

