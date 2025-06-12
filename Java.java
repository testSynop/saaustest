public class Java{

    public static  void main(String[] args) {
        int[] nums = {1, 3, 5,2, 7};
        int count = 1;
        int max = 1;
        for (int i = 1; i < nums.length ; i++) {
            if(nums[i] > nums[i-1])
                count++;
            else{
                max = Math.max(max,count);
                count = 1;
            }
        }
        max = Math.max(max,count);
        System.out.println(max);
    }
}

 