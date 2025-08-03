from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from .models import UserProfile
from .serializers import UserProfileSerializer
from .utils import verify_supabase_token

class UserProfileView(APIView):
    def post(self, request):
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        user_data = verify_supabase_token(token)

        if not user_data:
            return Response({"error": "Invalid or expired token"}, status=401)

        supabase_id = user_data['sub']
        data = request.data.copy()
        data['supabase_id'] = supabase_id

        profile, _ = UserProfile.objects.update_or_create(
            supabase_id=supabase_id,
            defaults=data
        )

        serializer = UserProfileSerializer(profile)
        return Response(serializer.data)
    
    def get(self, request):
        token = request.headers.get("Authorization", "").replace("Bearer ", "")
        user_data = verify_supabase_token(token)

        if not user_data:
            return Response({"error": "Invalid or expired token"}, status=401)

        supabase_id = user_data['sub']
        try:
            profile = UserProfile.objects.get(supabase_id=supabase_id)
        except UserProfile.DoesNotExist:
            return Response({"error": "Profile not found"}, status=404)

        serializer = UserProfileSerializer(profile)
        return Response(serializer.data)
