import os
import codecs

target_dir = r"e:\twmoa_1181_cn\twmoa_1181_cn\WoW Capycraft Sequito\Interface\AddOns\WCS_Brain"

exclude_files = ["WCS_Helpers.lua", "WCS_Brain.lua", "WCS_ClassEngine.lua", "WCS_Lua50_ErrorCheck.lua"]
patch_str = "if WCS_Brain and WCS_Brain.ENABLED == false then return end\n"

for filename in os.listdir(target_dir):
    if filename.endswith(".lua") and filename not in exclude_files:
        filepath = os.path.join(target_dir, filename)
        
        try:
            with codecs.open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            if "WCS_Brain.ENABLED == false then return end" not in content:
                # Tratar de ponerlo despues del header if exists
                if content.startswith("--[["):
                    end_comment = content.find("]]--")
                    if end_comment != -1:
                        new_content = content[:end_comment+4] + "\n" + patch_str + content[end_comment+4:]
                    else:
                        new_content = patch_str + content
                else:
                    new_content = patch_str + content
                    
                with codecs.open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                print(f"Patched: {filename}")
        except Exception as e:
            print(f"Error on {filename}: {e}")

print("Done")
