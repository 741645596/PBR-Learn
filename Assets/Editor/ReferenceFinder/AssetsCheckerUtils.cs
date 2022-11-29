using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UnityEditor;

class AssetsCheckerUtils
{
    public static string CheckPath
    {
        get
        {
            return "Assets/GameData/";
        }
    }

    public static List<string> SortByName(List<string> rslt)
    {
        rslt = rslt.OrderBy(
            x => {
                var assetPath = AssetDatabase.GUIDToAssetPath(x);
                return assetPath;
            }).ToList();

        rslt = rslt.OrderBy(
            x => {
                var assetPath = AssetDatabase.GUIDToAssetPath(x);
                var lastIndexOf = assetPath.LastIndexOf(".");
                if (lastIndexOf != -1)
                    return assetPath.Substring(lastIndexOf);
                else
                    return assetPath;
            }).ToList();
        return rslt;
    }
}
