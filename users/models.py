from django.db import models
import uuid

class UserProfile(models.Model):
    supabase_id = models.UUIDField(unique=True)  # 'sub' from Supabase JWT
    name = models.CharField(max_length=100)
    email = models.EmailField(blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    profile_image_url = models.URLField(blank=True, null=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name or str(self.supabase_id)
