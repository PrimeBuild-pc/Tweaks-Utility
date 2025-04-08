using System.Collections.Generic;
using System.IO;
using System.Text.Json;

namespace WinOptimizer.Services
{
    public class ProfileService
    {
        private const string ProfilesDirectory = "Profiles";
        
        public List<string> GetAvailableProfiles()
        {
            if (!Directory.Exists(ProfilesDirectory))
            {
                Directory.CreateDirectory(ProfilesDirectory);
                return new List<string>();
            }
            
            var files = Directory.GetFiles(ProfilesDirectory, "*.json");
            var profiles = new List<string>();
            
            foreach (var file in files)
            {
                profiles.Add(Path.GetFileNameWithoutExtension(file));
            }
            
            return profiles;
        }

        public void SaveProfile(string profileName, object profileData)
        {
            var filePath = Path.Combine(ProfilesDirectory, $"{profileName}.json");
            var json = JsonSerializer.Serialize(profileData);
            File.WriteAllText(filePath, json);
        }

        public T LoadProfile<T>(string profileName)
        {
            var filePath = Path.Combine(ProfilesDirectory, $"{profileName}.json");
            var json = File.ReadAllText(filePath);
            return JsonSerializer.Deserialize<T>(json);
        }
    }
}