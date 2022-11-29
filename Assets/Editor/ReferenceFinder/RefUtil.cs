using UnityEditor;
using UnityEngine;
public class RefUtil {
    public static string clipboard {
        get { return GUIUtility.systemCopyBuffer; }
        set { GUIUtility.systemCopyBuffer = value; }
    }

    public static Texture getTexture(string assetPath) {
        Texture tex = AssetDatabase.LoadAssetAtPath<Texture2D>(assetPath);
        if (tex != null)
            return tex;
        Texture tex2 = AssetDatabase.LoadAssetAtPath<Cubemap>(assetPath);
        if (tex2 != null)
            return tex2;

        return null;
    }

    public static string getExt(string assetPath) {
        var lastIndexOf = assetPath.LastIndexOf(".");
        if (lastIndexOf == -1)
            return "";

        return assetPath.Substring(lastIndexOf).ToLower();
    }
}