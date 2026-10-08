use proconio::{fastout, input};

#[fastout]
fn main() {
    input! {
        n: usize,
    }
    let ans = (n * (n + 1)) / 2;
    println!("{}", ans);
}
