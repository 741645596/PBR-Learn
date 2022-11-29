using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using UnityEditor;
using UnityEngine;

public class Fnt2FontSetting
{
    //[MenuItem("Assets/Fnt转FontSetting", true)]
    public static bool vDoIt()
    {
        string filePath = AssetDatabase.GetAssetPath(Selection.activeObject);
        return IsVaildFile(filePath);
    }

    //[MenuItem("Assets/Fnt转FontSetting", false, 0)]
    public static void DoIt()
    {
        string filePath = AssetDatabase.GetAssetPath(Selection.activeObject);
        Generate(filePath);
    }

    public static void Generate(string path)
    {
        // 是否是合法的路径
        if (!IsVaildFile(path))
        {
            Debug.LogWarning("错误提示：不存在.fnt格式文件");
            return;
        }

        // 创建FontSetting
        CreateFont(path);

        // 将png图片设置为Sprite(2D and UI)格式
        ResetPngFormat(path);

        // 删除Fnt文件
        DeleteFntFile(path);

        AssetDatabase.Refresh();
    }

    private static void ResetPngFormat(string fileName)
    {
        var pngPath = Path.ChangeExtension(fileName, ".png");
        AssetImporter assetImporter = AssetImporter.GetAtPath(pngPath);
        if (assetImporter == null)
        {
            Debug.LogWarning("错误提示：找不到fnt对应的png文件" + pngPath);
            return;
        }

        var textureImporter = assetImporter as TextureImporter;
        if (textureImporter != null)
        {
            textureImporter.textureType = TextureImporterType.Sprite;
        }
    }

    private static bool IsVaildFile(string fileName)
    {
        if (fileName.Contains(".fnt"))
        {
            return true;
        }

        // 查找相应文件是否存在
        var filePath = Path.ChangeExtension(fileName, ".fnt");
        return File.Exists(filePath);
    }

    private static void DeleteFntFile(string fileName)
    {
        var filePath = Path.ChangeExtension(fileName, ".fnt");
        File.Delete(filePath);
    }

    private static void CreateFont(string fileName)
    {
        // 适合不是xml格式文本模式
        var fntFilePath = Path.ChangeExtension(fileName, ".fnt");
        StreamReader reader = new StreamReader(new FileStream(fntFilePath, FileMode.Open));
        List<CharacterInfo> charList = new List<CharacterInfo>();
        Regex reg = new Regex(@"char  id=(?<id>\d+)\s+x=(?<x>\d+)\s+y=(?<y>\d+)\s+width=(?<width>\d+)\s+height=(?<height>\d+)\s+xoffset=(?<xoffset>(-|\d)+)\s+yoffset=(?<yoffset>(-|\d)+)\s+xadvance=(?<xadvance>\d+)\s+");
        string line = reader.ReadLine();
        int lineHeight = 65;
        int texWidth = 512;
        int texHeight = 512;
        var list = new List<CharacterInfo>();
        while (line != null)
        {
            if (line.IndexOf("char  id=") != -1)
            {
                Match match = reg.Match(line);
                if (match != Match.Empty)
                {
                    var id = System.Convert.ToInt32(match.Groups["id"].Value);
                    var x = System.Convert.ToInt32(match.Groups["x"].Value);
                    var y = System.Convert.ToInt32(match.Groups["y"].Value);
                    var width = System.Convert.ToInt32(match.Groups["width"].Value);
                    var height = System.Convert.ToInt32(match.Groups["height"].Value);
                    var xoffset = System.Convert.ToInt32(match.Groups["xoffset"].Value);
                    var yoffset = System.Convert.ToInt32(match.Groups["yoffset"].Value);
                    var xadvance = System.Convert.ToInt32(match.Groups["xadvance"].Value);
                    //Debug.Log("ID" + id);
                    CharacterInfo info = new CharacterInfo();
                    info.index = id;

                    float uvx = 1f * x / texWidth;
                    float uvy = 1 - (1f * y / texHeight);
                    float uvw = 1f * width / texWidth;
                    float uvh = -1f * height / texHeight;

                    info.uvBottomLeft = new Vector2(uvx, uvy);
                    info.uvBottomRight = new Vector2(uvx + uvw, uvy);
                    info.uvTopLeft = new Vector2(uvx, uvy + uvh);
                    info.uvTopRight = new Vector2(uvx + uvw, uvy + uvh);
                    info.minX = xoffset;
                    info.minY = yoffset + height / 2;
                    info.glyphWidth = width;
                    info.glyphHeight = -height;
                    info.advance = xadvance;

                    list.Add(info);
                }
            }
            else if (line.IndexOf("scaleW=") != -1)
            {
                Regex reg2 = new Regex(@"common lineHeight=(?<lineHeight>\d+)\s+.*scaleW=(?<scaleW>\d+)\s+scaleH=(?<scaleH>\d+)");
                Match match = reg2.Match(line);
                if (match != Match.Empty)
                {
                    lineHeight = System.Convert.ToInt32(match.Groups["lineHeight"].Value);
                    texWidth = System.Convert.ToInt32(match.Groups["scaleW"].Value);
                    texHeight = System.Convert.ToInt32(match.Groups["scaleH"].Value);
                }
            }
            line = reader.ReadLine();
        }


        var finnalPath = Path.ChangeExtension(fileName, ".png");
        Texture2D tex = AssetDatabase.LoadAssetAtPath<Texture2D>(finnalPath);
        if (tex == null)
        {
            Debug.LogError($"未找到fnt字体纹理{finnalPath}");
            reader.Close();
            return;
        }

        reader.Close();

        Material mat = new Material(Shader.Find("GUI/Text Shader"));
        mat.SetTexture("_MainTex", tex);
        Font font = new Font();
        font.material = mat; 
        AssetDatabase.CreateAsset(mat, Path.ChangeExtension(fileName, ".mat"));
        AssetDatabase.CreateAsset(font, Path.ChangeExtension(fileName, ".fontsettings"));
        font.characterInfo = list.ToArray();

        EditorUtility.SetDirty(font);
        AssetDatabase.SaveAssets();
        AssetDatabase.Refresh();
        Debug.Log("创建成功！");
    }
}